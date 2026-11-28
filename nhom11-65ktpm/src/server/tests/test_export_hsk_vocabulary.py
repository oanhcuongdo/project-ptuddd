import importlib.util
import json
from pathlib import Path

import pytest


EXPORTER_PATH = Path(__file__).resolve().parents[3] / "scripts" / "export_hsk_vocabulary.py"
SPEC = importlib.util.spec_from_file_location("export_hsk_vocabulary", EXPORTER_PATH)
assert SPEC is not None and SPEC.loader is not None
exporter = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(exporter)


def _write_lesson(directory: Path, pinyins: tuple[str, str]) -> None:
    directory.mkdir(parents=True)
    words = []
    for index in range(8):
        words.append({
            "id": f"word-{index}",
            "hanzi": "还" if index < 2 else f"字{index}",
            "pinyin": pinyins[index] if index < 2 else f"zì{index}",
            "hanViet": "hoàn",
            "meaningVi": "từ thử nghiệm",
            "example": None,
        })
    lesson = {
        "id": "hsk1-test-01",
        "level": "HSK1",
        "order": 1,
        "title": "Bài thử",
        "vocabulary": words,
        "grammarPoints": [{"id": "gp-test"}],
        "aiScenario": {"situation": "test"},
    }
    (directory / "lesson-01.json").write_text(
        json.dumps(lesson, ensure_ascii=False),
        encoding="utf-8",
    )


def test_export_allows_same_hanzi_with_different_pinyin(tmp_path, monkeypatch):
    lessons_dir = tmp_path / "lessons"
    _write_lesson(lessons_dir / "hsk1", ("hái", "huán"))
    monkeypatch.setattr(exporter, "LESSONS_DIR", lessons_dir)

    result = exporter.build_export()

    assert result["wordCount"] == 8
    assert [(word["hanzi"], word["pinyin"]) for word in result["vocabulary"][:2]] == [
        ("还", "hái"),
        ("还", "huán"),
    ]


def test_export_rejects_duplicate_hanzi_and_pinyin_pair(tmp_path, monkeypatch):
    lessons_dir = tmp_path / "lessons"
    _write_lesson(lessons_dir / "hsk1", ("huán", "huán"))
    monkeypatch.setattr(exporter, "LESSONS_DIR", lessons_dir)

    with pytest.raises(ValueError, match="duplicate hanzi/pinyin"):
        exporter.build_export()
