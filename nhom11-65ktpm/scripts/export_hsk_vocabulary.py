#!/usr/bin/env python3
"""Build the beginner thematic vocabulary export from lesson JSON files."""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LESSONS_DIR = ROOT / "data" / "lessons"
OUTPUT = ROOT / "data" / "hsk1_2_vocabulary.json"
WORD_FIELDS = ("id", "hanzi", "pinyin", "hanViet", "meaningVi", "example")


def build_export() -> dict:
    lessons = []
    vocabulary = []
    lesson_ids = set()
    word_ids = set()
    hanzi_pinyin_values = set()

    paths = sorted(
        path
        for level in ("hsk1", "hsk2")
        for path in (LESSONS_DIR / level).glob("lesson-*.json")
    )
    if not paths:
        raise ValueError(f"No lesson files found under {LESSONS_DIR}")

    for path in paths:
        lesson = json.loads(path.read_text(encoding="utf-8"))
        expected_level = path.parent.name.upper()
        if lesson.get("level") != expected_level:
            raise ValueError(f"{path}: level must be {expected_level}")
        if lesson["id"] in lesson_ids:
            raise ValueError(f"{path}: duplicate lesson id {lesson['id']}")
        lesson_ids.add(lesson["id"])

        words = lesson.get("vocabulary")
        if not isinstance(words, list) or not 8 <= len(words) <= 12:
            raise ValueError(f"{path}: vocabulary must contain 8–12 words")
        if not lesson.get("grammarPoints") or not lesson.get("aiScenario"):
            raise ValueError(f"{path}: grammarPoints and aiScenario are required")

        lessons.append({
            "id": lesson["id"],
            "level": expected_level,
            "order": lesson["order"],
            "title": lesson["title"],
        })
        for word in words:
            missing = [field for field in WORD_FIELDS if field not in word]
            if missing:
                raise ValueError(f"{path}: word is missing fields {', '.join(missing)}")
            if word["id"] in word_ids:
                raise ValueError(f"{path}: duplicate word id {word['id']}")
            hanzi_pinyin = (word["hanzi"], word["pinyin"])
            if hanzi_pinyin in hanzi_pinyin_values:
                raise ValueError(f"{path}: duplicate hanzi/pinyin {hanzi_pinyin}")
            word_ids.add(word["id"])
            hanzi_pinyin_values.add(hanzi_pinyin)
            vocabulary.append({
                "level": expected_level,
                "lessonId": lesson["id"],
                "lessonOrder": lesson["order"],
                "lessonTitle": lesson["title"],
                **{field: word[field] for field in WORD_FIELDS},
            })

    return {
        "schemaVersion": 1,
        "contentVersion": 1,
        "lessonCount": len(lessons),
        "wordCount": len(vocabulary),
        "lessons": lessons,
        "vocabulary": vocabulary,
    }


def main() -> None:
    export = build_export()
    OUTPUT.write_text(
        json.dumps(export, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {export['wordCount']} words from {export['lessonCount']} lessons to {OUTPUT}")


if __name__ == "__main__":
    main()
