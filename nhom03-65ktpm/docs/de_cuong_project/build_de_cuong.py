# -*- coding: utf-8 -*-
"""Sinh đề cương DOCX, tự động tính số trang mục lục và xuất PDF xem trước."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, Rectangle

sys.path.insert(0, str(Path(__file__).resolve().parent))

from content_a import add_section_1_3
from content_b import add_section_4
from content_c import add_section_5_6
from docx_helpers import ReportBuilder

BASE_DIR = Path(__file__).resolve().parent
ASSET_DIR = BASE_DIR / "assets"
FINAL_DOCX = BASE_DIR / "DeCuong_Project_CuoiKy_Nhom03.docx"
FINAL_PDF = BASE_DIR / "DeCuong_Project_CuoiKy_Nhom03.pdf"
TMP_DOCX = BASE_DIR / "_tmp_de_cuong.docx"
TMP_PDF = BASE_DIR / "_tmp_de_cuong.pdf"

TOC_ENTRIES = [
    ("1. MỞ ĐẦU", 0),
    ("1.1. Bối cảnh và lý do chọn đề tài", 1),
    ("1.2. Mục đích của đề cương", 1),
    ("1.3. Phương pháp thực hiện", 1),
    ("2. TỔNG HỢP CÁC ỨNG DỤNG ĐÃ PHÂN TÍCH, THIẾT KẾ", 0),
    ("2.1. Cơ sở tổng hợp", 1),
    ("2.2. Kết quả phân tích, thiết kế của từng ứng dụng", 1),
    ("2.3. Bảng tổng hợp và so sánh", 1),
    ("2.4. Nhận xét chung", 1),
    ("3. LỰA CHỌN ỨNG DỤNG CHO PROJECT CUỐI KỲ", 0),
    ("3.1. Tiêu chí lựa chọn", 1),
    ("3.2. Đánh giá theo tiêu chí", 1),
    ("3.3. Quyết định lựa chọn", 1),
    ("4. ĐỀ CƯƠNG CHI TIẾT DỰ ÁN", 0),
    ("4.1. Thông tin chung", 1),
    ("4.2. Mục tiêu của dự án", 1),
    ("4.3. Phạm vi của dự án", 1),
    ("4.4. Tác nhân và chức năng chính", 1),
    ("4.5. Kiến trúc và mô hình dữ liệu", 1),
    ("4.6. Yêu cầu phi chức năng", 1),
    ("4.7. Sản phẩm bàn giao", 1),
    ("5. KẾ HOẠCH THỰC HIỆN", 0),
    ("5.1. Phương pháp và quy trình", 1),
    ("5.2. Phân công nhóm", 1),
    ("5.3. Tiến độ thực hiện", 1),
    ("5.4. Cột mốc và sản phẩm", 1),
    ("5.5. Kế hoạch kiểm thử", 1),
    ("5.6. Quản lý rủi ro", 1),
    ("5.7. Tiêu chí nghiệm thu", 1),
    ("5.8. Cơ chế theo dõi và báo cáo", 1),
    ("6. KẾT LUẬN", 0),
    ("TÀI LIỆU THAM KHẢO", 0),
    ("PHỤ LỤC A. CHECKLIST ĐỐI CHIẾU YÊU CẦU", 0),
    ("PHỤ LỤC B. MA TRẬN USE CASE – CHỨC NĂNG – PHÂN CÔNG", 0),
]

MEMBERS = [
    ("Minh", "Nhóm trưởng – Kiến trúc, xác thực, CRUD chính"),
    ("Đạt", "Thành viên – Giao diện responsive, bản Web"),
    ("Hạnh", "Thành viên – Tag, vị trí và bản đồ"),
    ("Quân", "Thành viên – Chia sẻ, mượn, thông báo"),
    ("Đăng", "Thành viên – Gợi ý, kiểm thử, đóng gói"),
]


def _box(ax, x, y, w, h, title, subtitle=None, fill="white", fontsize=10.8):
    rect = Rectangle(
        (x, y), w, h, facecolor=fill, edgecolor="black", linewidth=1.15, zorder=2
    )
    ax.add_patch(rect)
    if subtitle:
        ax.text(
            x + w / 2, y + h * 0.66, title,
            ha="center", va="center", fontsize=fontsize, fontweight="bold", zorder=3
        )
        ax.text(
            x + w / 2, y + h * 0.28, subtitle,
            ha="center", va="center", fontsize=fontsize - 1.7, zorder=3
        )
    else:
        ax.text(
            x + w / 2, y + h / 2, title,
            ha="center", va="center", fontsize=fontsize, fontweight="bold", zorder=3
        )


def _arrow(ax, start, end, style="-|>", linestyle="-", lw=1.1):
    arrow = FancyArrowPatch(
        start, end, arrowstyle=style, mutation_scale=12,
        linewidth=lw, linestyle=linestyle, color="black", zorder=4,
        shrinkA=0, shrinkB=0,
    )
    ax.add_patch(arrow)


def make_architecture_figure():
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    plt.rcParams["font.family"] = "DejaVu Sans"
    fig, ax = plt.subplots(figsize=(9.2, 5.25))
    ax.set_xlim(0, 13.2)
    ax.set_ylim(0, 7.5)
    ax.axis("off")

    _box(ax, 4.3, 6.55, 3.6, 0.62, "Người dùng", "Android • Web", fill="white", fontsize=10.8)
    _box(ax, 3.2, 5.15, 5.8, 0.95, "Lớp giao diện Flutter",
         "Pages • Widgets • Responsive UI", fill="white", fontsize=10.8)
    _box(ax, 3.2, 3.85, 5.8, 0.9, "Lớp nghiệp vụ",
         "functions.dart • services • struct models", fill="#F2F2F2", fontsize=10.8)
    _box(ax, 3.1, 1.15, 6.0, 1.2, "Supabase",
         "PostgREST • Realtime • Storage • RLS", fill="#E6E6E6", fontsize=11.2)

    _box(ax, 0.25, 3.95, 2.55, 0.8, "Firebase Authentication",
         "Email/Google • ID token", fill="#FAFAFA", fontsize=9.4)
    _box(ax, 9.95, 3.95, 2.95, 0.8, "Edge Function",
         "Đổi ID token → JWT", fill="#FAFAFA", fontsize=9.4)
    _box(ax, 9.95, 2.0, 2.95, 0.8, "Firebase Cloud Messaging",
         "Thông báo đẩy", fill="#FAFAFA", fontsize=8.9)

    _arrow(ax, (6.1, 6.55), (6.1, 6.10))
    _arrow(ax, (6.1, 5.15), (6.1, 4.75))
    _arrow(ax, (6.1, 3.85), (6.1, 2.35))

    _arrow(ax, (3.2, 4.35), (2.80, 4.35))
    # Firebase Auth -> Edge Function (đường vòng phía trên lớp nghiệp vụ)
    ax.plot([1.52, 1.52, 11.42, 11.42], [4.75, 4.95, 4.95, 4.75],
            color="black", linewidth=1.0, linestyle=(0, (4, 2)), zorder=1)
    _arrow(ax, (11.42, 4.95), (11.42, 4.75))
    ax.text(6.1, 5.00, "ID token → JWT", ha="center", va="center",
            fontsize=8.3, bbox=dict(facecolor="white", edgecolor="none", pad=1.0), zorder=5)

    # Edge Function -> Supabase
    ax.plot([11.42, 11.42, 9.10], [3.95, 1.75, 1.75],
            color="black", linewidth=1.1, zorder=1)
    _arrow(ax, (9.55, 1.75), (9.10, 1.75))
    ax.text(11.55, 3.35, "JWT", ha="left", va="center", rotation=90, fontsize=8.3)

    # FCM -> lớp giao diện (push)
    ax.plot([12.90, 13.05, 13.05, 9.00], [2.40, 2.40, 5.62, 5.62],
            color="black", linewidth=1.0, linestyle=(0, (4, 2)), zorder=1)
    _arrow(ax, (13.05, 5.62), (9.00, 5.62))
    ax.text(13.02, 4.0, "push", ha="right", va="center", rotation=90, fontsize=8.0)

    ax.text(0.2, 0.35, "Đường liền: luồng dữ liệu chính    Đường đứt: xác thực và thông báo",
            ha="left", va="center", fontsize=8.0)
    fig.tight_layout(pad=0.25)
    out = ASSET_DIR / "architecture.png"
    fig.savefig(out, dpi=300, bbox_inches="tight", facecolor="white")
    plt.close(fig)


def make_gantt_figure():
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    plt.rcParams["font.family"] = "DejaVu Sans"
    tasks = [
        ("Khởi tạo và thiết kế", 1, 1),
        ("Xác thực, schema, RLS", 1, 2),
        ("Tài liệu, tệp, tìm kiếm", 3, 4),
        ("Tag và giao diện responsive", 4, 5),
        ("Chia sẻ quyền và mượn", 5, 6),
        ("Thông báo, vị trí, gợi ý", 6, 6),
        ("Kiểm thử và UAT", 7, 7),
        ("Đóng gói và báo cáo", 8, 8),
    ]
    shades = ["#D9D9D9", "#C9C9C9", "#BFBFBF", "#B3B3B3",
              "#A6A6A6", "#999999", "#CCCCCC", "#D9D9D9"]
    fig, ax = plt.subplots(figsize=(7.8, 5.9))
    fig.subplots_adjust(left=0.38, right=0.98, top=0.90, bottom=0.12)
    n = len(tasks)
    for idx, (label, start, end) in enumerate(tasks):
        ax.barh(
            idx, end - start + 1, left=start - 1, height=0.56,
            color=shades[idx], edgecolor="black", linewidth=0.9, zorder=3
        )
    for x in (2, 4, 6):
        ax.axvline(x, color="black", linewidth=0.7, linestyle=(0, (3, 3)), zorder=1)
    for sprint, center in enumerate((1, 3, 5, 7), start=1):
        ax.text(center, -0.85, f"Sprint {sprint}", ha="center", va="center",
                fontsize=8.8, fontweight="bold")
    ax.set_xlim(0, 8)
    ax.set_ylim(n - 0.4, -1.15)
    ax.set_xticks([i + 0.5 for i in range(8)])
    ax.set_xticklabels([f"T{i}" for i in range(1, 9)], fontsize=8.6)
    ax.set_yticks(range(n))
    ax.set_yticklabels([task[0] for task in tasks], fontsize=8.7)
    ax.tick_params(axis="x", length=0, pad=2)
    ax.tick_params(axis="y", length=0, pad=4)
    ax.grid(axis="x", color="#BFBFBF", linewidth=0.6, linestyle=":", zorder=0)
    for spine in ("top", "right", "left"):
        ax.spines[spine].set_visible(False)
    ax.spines["bottom"].set_linewidth(0.8)
    out = ASSET_DIR / "gantt.png"
    fig.savefig(out, dpi=300, facecolor="white")
    plt.close(fig)


def _normalize(text: str) -> str:
    text = text.replace("\u00a0", " ").replace("\u2022", " ")
    text = text.replace("–", "-").replace("—", "-")
    return re.sub(r"\s+", " ", text).strip().lower()


def _pdf_pages(pdf_path: Path) -> int:
    result = subprocess.run(
        ["pdfinfo", str(pdf_path)], capture_output=True, text=True, check=True
    )
    match = re.search(r"Pages:\s+(\d+)", result.stdout)
    if not match:
        raise RuntimeError("Không đọc được số trang PDF")
    return int(match.group(1))


def _page_text(pdf_path: Path, page: int) -> str:
    result = subprocess.run(
        ["pdftotext", "-layout", "-f", str(page), "-l", str(page), str(pdf_path), "-"],
        capture_output=True, text=True, check=True
    )
    return result.stdout


def compute_page_map(pdf_path: Path):
    total = _pdf_pages(pdf_path)
    pages = {i: _normalize(_page_text(pdf_path, i)) for i in range(1, total + 1)}

    first_key = _normalize(TOC_ENTRIES[0][0])
    start_page = None
    for i in range(2, total + 1):
        if first_key in pages[i] and "mục lục" not in pages[i]:
            start_page = i
            break
    if start_page is None:
        start_page = 3

    page_map = {}
    current = start_page
    for text, _level in TOC_ENTRIES:
        key = _normalize(text)
        found = None
        for i in range(current, total + 1):
            if key in pages[i]:
                found = i
                break
        if found:
            page_map[text] = str(found)
            current = found
    return page_map, start_page, total


def convert_to_pdf(docx_path: Path, out_dir: Path):
    subprocess.run(
        [
            "soffice", "--headless",
            "-env:UserInstallation=file:///tmp/lo_de_cuong_profile",
            "--convert-to", "pdf", "--outdir", str(out_dir), str(docx_path),
        ],
        capture_output=True, text=True, check=True,
    )


def build(page_map=None):
    b = ReportBuilder(toc_pages=page_map or {}, toc_entries=TOC_ENTRIES)
    b.add_cover(MEMBERS)
    b.add_toc()
    add_section_1_3(b)
    add_section_4(b)
    add_section_5_6(b)
    return b


def main():
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    make_architecture_figure()
    make_gantt_figure()

    for path in (TMP_DOCX, TMP_PDF, FINAL_DOCX, FINAL_PDF):
        if path.exists():
            path.unlink()

    # Lượt 1: bản nháp để xác định số trang thực tế
    b1 = build()
    b1.save(TMP_DOCX)
    convert_to_pdf(TMP_DOCX, BASE_DIR)
    page_map, start_page, total = compute_page_map(TMP_PDF)
    print(f"Bản nháp: {total} trang; nội dung bắt đầu từ trang {start_page}.")
    print("Mục lục tính được:")
    for text, _ in TOC_ENTRIES:
        print(f"  {page_map.get(text, '??'):>3}  {text}")

    # Lượt 2: điền số trang mục lục; lặp lại nếu bố cục thay đổi
    for attempt in range(1, 4):
        b2 = build(page_map)
        b2.save(FINAL_DOCX)
        convert_to_pdf(FINAL_DOCX, BASE_DIR)
        actual_map, _, final_total = compute_page_map(FINAL_PDF)
        if actual_map == page_map:
            print(f"Mục lục ổn định sau lượt {attempt}.")
            break
        print(f"Lượt {attempt}: số trang thay đổi, cập nhật lại mục lục.")
        page_map = actual_map

    if TMP_PDF.exists():
        TMP_PDF.unlink()
    if TMP_DOCX.exists():
        TMP_DOCX.unlink()

    final_total = _pdf_pages(FINAL_PDF)
    print(f"Đã tạo: {FINAL_DOCX}")
    print(f"Đã tạo: {FINAL_PDF} ({final_total} trang)")


if __name__ == "__main__":
    main()
