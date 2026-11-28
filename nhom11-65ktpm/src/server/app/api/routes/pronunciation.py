from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from typing import Optional
import os
import tempfile
import json
import re
import httpx

from app.core.config import settings
from app.api.deps import CurrentUser

router = APIRouter(prefix="/pronunciation", tags=["pronunciation"])

MAX_AUDIO_SIZE = 2 * 1024 * 1024  # 2MB

INITIALS = ['zh', 'ch', 'sh', 'b', 'p', 'm', 'f', 'd', 't', 'n', 'l', 'g', 'k', 'h', 'j', 'q', 'x', 'r', 'z', 'c', 's', 'y', 'w']
TONE_MAP = {
    'āēīōūǖ': 1,
    'áéíóúǘ': 2,
    'ǎěǐǒǔǚ': 3,
    'àèìòùǜ': 4,
}
PLAIN_MAP = {
    'āáǎà': 'a', 'ēéěè': 'e', 'īíǐì': 'i', 'ōóǒò': 'o', 'ūúǔù': 'u', 'ǖǘǚǜ': 'ü',
}

def split_pinyin(syllable: str) -> dict:
    s = syllable.strip().lower()
    tone = 5
    if s and s[-1] in '12345':
        tone = int(s[-1])
        s = s[:-1]

    cleaned = []
    for ch in s:
        rep = ch
        for marks, t in TONE_MAP.items():
            if ch in marks and tone == 5:
                tone = t
        for marks, p in PLAIN_MAP.items():
            if ch in marks:
                rep = p
        cleaned.append(rep)

    s = "".join(cleaned)
    s = re.sub(r'[^a-zü]', '', s)

    for init in INITIALS:
        if s.startswith(init) and len(s) > len(init):
            return {"initial": init, "final": s[len(init):], "tone": tone}
    return {"initial": "", "final": s, "tone": tone}

@router.post("/assess")
async def assess_pronunciation(
    user: CurrentUser,
    reference_text: str = Form(..., min_length=1),
    audio_file: UploadFile = File(...),
    reference_pinyin: Optional[str] = Form(None),
):
    """
    API Cham phat am truc tuyen voi Azure Speech Pronunciation Assessment (zh-CN)
    Theo hop dong du lieu: yeu cau dang nhap (CurrentUser), tra ve PronunciationResult, loi 503 khi khong co key
    """
    if not audio_file.filename.lower().endswith(".wav"):
        raise HTTPException(status_code=400, detail="Chi chap nhan file am thanh dinh dang WAV")

    content = await audio_file.read()
    if len(content) > MAX_AUDIO_SIZE:
        raise HTTPException(status_code=400, detail="File am thanh vuot qua gioi han 2MB")

    # Neu server khong co Azure Speech Key thi tra ve 503 de app tu fallback ve offline
    if not settings.AZURE_SPEECH_KEY:
        raise HTTPException(status_code=503, detail="Dich vu cham phat am Azure online chua duoc cau hinh tren server")

    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
        tmp.write(content)
        tmp_path = tmp.name

    try:
        url = f"https://{settings.AZURE_SPEECH_REGION}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=zh-CN"
        pron_params = {
            "ReferenceText": reference_text,
            "GradingSystem": "HundredMark",
            "Granularity": "Phoneme",
            "Dimension": "Comprehensive",
            "EnableMiscue": True,
        }
        headers = {
            "Ocp-Apim-Subscription-Key": settings.AZURE_SPEECH_KEY,
            "Content-Type": "audio/wav; codecs=audio/pcm; samplerate=16000",
            "Pronunciation-Assessment": json.dumps(pron_params),
            "Accept": "application/json",
        }
        async with httpx.AsyncClient() as client:
            with open(tmp_path, "rb") as f:
                resp = await client.post(url, headers=headers, content=f.read(), timeout=10.0)

        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail=f"Loi goi Azure Speech API: {resp.status_code}")

        azure_data = resp.json()
        nbest = azure_data.get("NBest", [])
        if not nbest:
            raise HTTPException(status_code=502, detail="Khong nhan duoc ket qua tu Azure")

        first = nbest[0]
        pron = first.get("PronunciationAssessment", {})
        accuracy = float(pron.get("AccuracyScore", 0.0))
        fluency = float(pron.get("FluencyScore", 0.0))
        completeness = float(pron.get("CompletenessScore", 0.0))
        overall = float(pron.get("PronScore", accuracy))

        # Chuyen doi sang dinh dang hop dong PronunciationResult
        chars = [c for c in reference_text if '\u4e00' <= c <= '\u9fff']
        ref_pinyins = reference_pinyin.strip().split() if reference_pinyin else []

        words_raw = first.get("Words", [])
        # Duyet tat ca syllables tu Azure (mot Word co the chua nhieu Syllables)
        azure_syllables = []
        for w in words_raw:
            syls = w.get("Syllables")
            if syls:
                for s in syls:
                    azure_syllables.append((w, s))
            else:
                azure_syllables.append((w, None))

        syllables = []
        tone_scores = []
        for i, c in enumerate(chars):
            # Lay expected tu reference_pinyin do client gui len
            if i < len(ref_pinyins):
                exp_parts = split_pinyin(ref_pinyins[i])
            else:
                exp_parts = {"initial": "", "final": "", "tone": 5}

            w_info, s_info = azure_syllables[i] if i < len(azure_syllables) else (None, None)

            s_score = accuracy
            errs = []
            act_parts = None

            if w_info is not None:
                w_pron = w_info.get("PronunciationAssessment", {})
                err_type = w_pron.get("ErrorType", "None")

                if s_info is not None:
                    s_pron = s_info.get("PronunciationAssessment", {})
                    s_score = float(s_pron.get("AccuracyScore", accuracy))
                    raw_syl = s_info.get("Syllable", "")
                    act_parts = split_pinyin(raw_syl) if raw_syl else exp_parts

                    phonemes = s_info.get("Phonemes", [])
                    if phonemes:
                        for idx, p in enumerate(phonemes):
                            p_score = float(p.get("PronunciationAssessment", {}).get("AccuracyScore", 100))
                            if p_score < 60:
                                if idx == 0 and len(phonemes) > 1:
                                    errs.append("initial")
                                else:
                                    errs.append("final")
                else:
                    s_score = float(w_pron.get("AccuracyScore", accuracy))
                    act_parts = exp_parts

                if err_type == "Omission":
                    errs.append("missing")
                    act_parts = None
                elif err_type == "Mispronunciation" and not errs:
                    errs.append("initial")

            # Danh gia thanh dieu
            syl_tone = s_score
            if act_parts and exp_parts["tone"] != 5:
                if act_parts["tone"] != exp_parts["tone"] and act_parts["tone"] != 5:
                    errs.append("tone")
                    syl_tone = max(0.0, s_score - 40.0)
            tone_scores.append(syl_tone)

            status = "ok"
            if s_score < 60 or "missing" in errs:
                status = "error"
            elif s_score < 80 or errs:
                status = "warn"

            unique_errs = list(dict.fromkeys(errs))

            syllables.append({
                "hanzi": c,
                "expected": exp_parts,
                "actual": act_parts,
                "score": s_score,
                "status": status,
                "errors": unique_errs,
            })

        calc_tone = round(sum(tone_scores) / len(tone_scores), 1) if tone_scores else accuracy

        return {
            "overall": overall,
            "accuracy": accuracy,
            "tone": calc_tone,
            "fluency": fluency,
            "completeness": completeness,
            "source": "online",
            "recognized_text": first.get("Display", reference_text),
            "syllables": syllables,
        }
    finally:
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except Exception:
                pass
