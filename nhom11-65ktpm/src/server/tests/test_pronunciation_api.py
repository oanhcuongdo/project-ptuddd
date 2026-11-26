import httpx
from app.core.config import settings

def test_health_check(client):
    resp = client.get("/api/health")
    assert resp.status_code == 200

def test_pronunciation_assess_unauthorized(client):
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好"},
        files={"audio_file": ("test.wav", b"RIFF....WAVEfmt ....data....", "audio/wav")},
    )
    assert resp.status_code == 401

def test_pronunciation_assess_rejects_non_wav(client, auth_headers):
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好"},
        files={"audio_file": ("test.mp3", b"fake audio content", "audio/mpeg")},
        headers=auth_headers,
    )
    assert resp.status_code == 400
    assert "WAV" in resp.json()["detail"]

def test_pronunciation_assess_rejects_ogg(client, auth_headers):
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好"},
        files={"audio_file": ("audio.ogg", b"OggS...", "audio/ogg")},
        headers=auth_headers,
    )
    assert resp.status_code == 400

def test_pronunciation_assess_rejects_m4a(client, auth_headers):
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好"},
        files={"audio_file": ("audio.m4a", b"ftypM4A ....", "audio/m4a")},
        headers=auth_headers,
    )
    assert resp.status_code == 400

def test_pronunciation_assess_empty_text(client, auth_headers):
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": ""},
        files={"audio_file": ("test.wav", b"RIFF....WAVEfmt ....data....", "audio/wav")},
        headers=auth_headers,
    )
    # FastAPI tra ve 422 Unprocessable Entity khi min_length validation fail
    assert resp.status_code == 422

def test_pronunciation_assess_without_azure_key_returns_503(client, auth_headers, monkeypatch):
    monkeypatch.setattr(settings, "AZURE_SPEECH_KEY", "")
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好"},
        files={"audio_file": ("test.wav", b"RIFF....WAVEfmt ....data....", "audio/wav")},
        headers=auth_headers,
    )
    # Khi chua co key Azure that, server tra ve 503 de mobile tu fallback ve offline
    assert resp.status_code == 503
    assert "chua duoc cau hinh" in resp.json()["detail"]

def test_pronunciation_assess_success_mock_azure(client, auth_headers, monkeypatch):
    monkeypatch.setattr(settings, "AZURE_SPEECH_KEY", "test_mock_key_123")
    monkeypatch.setattr(settings, "AZURE_SPEECH_REGION", "eastasia")

    fake_azure_response = {
        "RecognitionStatus": "Success",
        "NBest": [
            {
                "Display": "你好",
                "PronunciationAssessment": {
                    "AccuracyScore": 92.0,
                    "FluencyScore": 88.0,
                    "CompletenessScore": 100.0,
                    "PronScore": 90.0,
                },
                "Words": [
                    {
                        "Word": "你好",
                        "PronunciationAssessment": {
                            "AccuracyScore": 92.0,
                            "ErrorType": "None",
                        },
                        "Syllables": [
                            {
                                "Syllable": "nǐ",
                                "PronunciationAssessment": {"AccuracyScore": 95.0},
                                "Phonemes": [
                                    {"Phoneme": "n", "PronunciationAssessment": {"AccuracyScore": 96.0}},
                                    {"Phoneme": "i", "PronunciationAssessment": {"AccuracyScore": 94.0}},
                                ],
                            },
                            {
                                "Syllable": "hǎo",
                                "PronunciationAssessment": {"AccuracyScore": 89.0},
                                "Phonemes": [
                                    {"Phoneme": "h", "PronunciationAssessment": {"AccuracyScore": 90.0}},
                                    {"Phoneme": "ao", "PronunciationAssessment": {"AccuracyScore": 88.0}},
                                ],
                            },
                        ],
                    }
                ],
            }
        ],
    }

    class MockResponse:
        status_code = 200

        def json(self):
            return fake_azure_response

    async def mock_post(*args, **kwargs):
        return MockResponse()

    monkeypatch.setattr(httpx.AsyncClient, "post", mock_post)

    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好", "reference_pinyin": "nǐ hǎo"},
        files={"audio_file": ("test.wav", b"RIFF....WAVEfmt ....data....", "audio/wav")},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["source"] == "online"
    assert data["overall"] == 90.0
    assert data["accuracy"] == 92.0
    assert data["fluency"] == 88.0
    assert data["completeness"] == 100.0
    assert len(data["syllables"]) == 2

    # Syllable 1: 你
    syl1 = data["syllables"][0]
    assert syl1["hanzi"] == "你"
    assert syl1["expected"] == {"initial": "n", "final": "i", "tone": 3}
    assert syl1["actual"] == {"initial": "n", "final": "i", "tone": 3}
    assert syl1["status"] == "ok"
    assert syl1["errors"] == []

    # Syllable 2: 好
    syl2 = data["syllables"][1]
    assert syl2["hanzi"] == "好"
    assert syl2["expected"] == {"initial": "h", "final": "ao", "tone": 3}
    assert syl2["status"] == "ok"
