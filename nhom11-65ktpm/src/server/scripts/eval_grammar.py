"""Đánh giá độ chính xác phân tích ngữ pháp của trợ lý AI trên bộ câu kiểm thử.

GỌI API THẬT (tốn phí) — chạy thủ công, không chạy trong CI:

    cd nhom11-65ktpm/src/server
    AI_PROVIDER=anthropic ANTHROPIC_API_KEY=... python -m scripts.eval_grammar
    AI_PROVIDER=openai OPENAI_API_KEY=... python -m scripts.eval_grammar

Mỗi câu được chấm 2 tiêu chí:
- đúng/sai: model nhận định câu đúng hay có lỗi khớp với nhãn;
- loại lỗi: với câu sai, ít nhất một loại lỗi model trả về nằm trong loại lỗi mong đợi.
"""

import asyncio
import json
from pathlib import Path

from app.core.config import settings
from app.services.ai.pricing import Usage, estimate_cost_usd
from app.services.ai.prompts import LessonContext
from app.services.ai.providers import build_provider

CASES = Path(__file__).resolve().parents[1] / "tests" / "data" / "grammar_eval_cases.json"

CONTEXT = LessonContext(
    lesson_id=None,
    title="Ôn tập HSK 1",
    topic="Giới thiệu bản thân, gia đình, mua sắm",
    description=None,
    scenario=None,
    grammar_points=[
        {"id": "gp-shi", "pattern": "A 是 B", "explanationVi": "Câu với 是 nối hai danh từ"},
        {"id": "gp-time-place", "pattern": "S + thời gian/địa điểm + V", "explanationVi": "Trạng ngữ đứng trước động từ"},
        {"id": "gp-measure", "pattern": "Số + lượng từ + danh từ", "explanationVi": "Giữa số và danh từ cần lượng từ"},
        {"id": "gp-bu-mei", "pattern": "不 / 没", "explanationVi": "没 phủ định quá khứ và 有, 不 phủ định hiện tại/tương lai"},
        {"id": "gp-le", "pattern": "V + 了", "explanationVi": "了 biểu thị hành động đã hoàn thành"},
    ],
).render()


async def main() -> None:
    provider = build_provider(settings.AI_PROVIDER)
    cases = json.loads(CASES.read_text(encoding="utf-8"))
    correct_judgement = correct_type = wrong_cases = 0
    usage = Usage()

    for case in cases:
        result = await provider.analyze_grammar(
            lesson_context=CONTEXT, question=case["question"], answer=case["answer"], cache_key="eval"
        )
        usage = usage + result.usage
        a = result.analysis
        predicted_correct = not a.errors
        ok_judgement = predicted_correct == case["expect_correct"]
        correct_judgement += ok_judgement
        types = {e.error_type for e in a.errors}
        type_note = ""
        if not case["expect_correct"]:
            wrong_cases += 1
            ok_type = bool(types & set(case["expect_error_types"]))
            correct_type += ok_type
            type_note = f" loại lỗi {'OK' if ok_type else 'SAI'} {sorted(types)}"
        mark = "OK " if ok_judgement else "SAI"
        print(f"[{mark}] {case['id']:<15} {case['answer']:<12} -> {a.corrected_sentence} ({a.score}){type_note}")

    print(f"\nProvider: {provider.name} / {provider.model}")
    print(f"Nhận định đúng/sai: {correct_judgement}/{len(cases)}")
    print(f"Nhận đúng loại lỗi (câu sai): {correct_type}/{wrong_cases}")
    print(f"Token: {usage} ~ ${estimate_cost_usd(provider.model, usage):.4f}")


if __name__ == "__main__":
    asyncio.run(main())
