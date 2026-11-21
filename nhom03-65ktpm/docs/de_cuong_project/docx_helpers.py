# -*- coding: utf-8 -*-
"""Các hàm dựng DOCX dùng chung cho đề cương."""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.table import WD_ALIGN_VERTICAL, WD_TABLE_ALIGNMENT
from docx.enum.text import (
    WD_ALIGN_PARAGRAPH,
    WD_LINE_SPACING,
    WD_TAB_ALIGNMENT,
    WD_TAB_LEADER,
)
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

FONT = "Times New Roman"
BLACK = RGBColor(0, 0, 0)
TEXT_WIDTH_CM = 16.0


def _set_run_font(run, size=13, bold=False, italic=False, name=FONT):
    run.font.name = name
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = BLACK
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.insert(0, rfonts)
    for attr in ("w:ascii", "w:hAnsi", "w:cs", "w:eastAsia"):
        rfonts.set(qn(attr), name)


def _set_style_font(style, size, bold=False, italic=False):
    style.font.name = FONT
    style.font.size = Pt(size)
    style.font.bold = bold
    style.font.italic = italic
    style.font.color.rgb = BLACK
    rpr = style.element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.insert(0, rfonts)
    for attr in ("w:ascii", "w:hAnsi", "w:cs", "w:eastAsia"):
        rfonts.set(qn(attr), FONT)


def _set_cell_margins(cell, top=60, start=90, bottom=60, end=90):
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_mar = tc_pr.find(qn("w:tcMar"))
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for tag, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{tag}"))
        if node is None:
            node = OxmlElement(f"w:{tag}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def _shade_cell(cell, fill="D9D9D9"):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)
    tc_pr.append(shd)


def _set_table_borders(table, sz=6):
    tbl_pr = table._tbl.tblPr
    borders = OxmlElement("w:tblBorders")
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        element = OxmlElement(f"w:{edge}")
        element.set(qn("w:val"), "single")
        element.set(qn("w:sz"), str(sz))
        element.set(qn("w:space"), "0")
        element.set(qn("w:color"), "000000")
        borders.append(element)
    tbl_pr.append(borders)


def _set_repeat_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    header = OxmlElement("w:tblHeader")
    header.set(qn("w:val"), "true")
    tr_pr.append(header)


def _set_cant_split(row):
    tr_pr = row._tr.get_or_add_trPr()
    cant_split = OxmlElement("w:cantSplit")
    cant_split.set(qn("w:val"), "true")
    tr_pr.append(cant_split)


def _add_field(paragraph, instruction: str, placeholder: str = "1", size=10):
    run = paragraph.add_run()
    _set_run_font(run, size=size)
    fld_begin = OxmlElement("w:fldChar")
    fld_begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = f" {instruction} "
    separate = OxmlElement("w:fldChar")
    separate.set(qn("w:fldCharType"), "separate")
    text = OxmlElement("w:t")
    text.text = placeholder
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    run._r.append(fld_begin)
    run._r.append(instr)
    run._r.append(separate)
    run._r.append(text)
    run._r.append(end)


def _bottom_border(paragraph, sz=8):
    p_pr = paragraph._p.get_or_add_pPr()
    borders = OxmlElement("w:pBdr")
    bottom = OxmlElement("w:bottom")
    bottom.set(qn("w:val"), "single")
    bottom.set(qn("w:sz"), str(sz))
    bottom.set(qn("w:space"), "4")
    bottom.set(qn("w:color"), "000000")
    borders.append(bottom)
    p_pr.append(borders)


class ReportBuilder:
    """Bọc python-docx và giữ các quy ước trình bày học thuật."""

    def __init__(self, toc_pages: dict[str, int] | None = None, toc_entries=None):
        self.doc = Document()
        self.toc_pages = toc_pages or {}
        self.toc_entries = toc_entries or []
        self.table_no = 0
        self.figure_no = 0
        self._setup_page()
        self._setup_styles()
        self._setup_header_footer()

    # ------------------------------------------------------------------ setup
    def _setup_page(self):
        section = self.doc.sections[0]
        section.page_width = Cm(21.0)
        section.page_height = Cm(29.7)
        section.top_margin = Cm(2.5)
        section.bottom_margin = Cm(2.5)
        section.left_margin = Cm(3.0)
        section.right_margin = Cm(2.0)
        section.header_distance = Cm(1.2)
        section.footer_distance = Cm(1.2)
        section.different_first_page_header_footer = True

    def _setup_styles(self):
        styles = self.doc.styles
        normal = styles["Normal"]
        _set_style_font(normal, 13)
        normal.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        normal.paragraph_format.line_spacing = 1.5
        normal.paragraph_format.space_before = Pt(0)
        normal.paragraph_format.space_after = Pt(6)
        normal.paragraph_format.first_line_indent = Cm(1.0)

        for name, size, bold, italic, before, after in (
            ("Heading 1", 16, True, False, 0, 10),
            ("Heading 2", 14, True, False, 12, 6),
            ("Heading 3", 13, True, True, 10, 4),
        ):
            style = styles[name]
            _set_style_font(style, size, bold=bold, italic=italic)
            pf = style.paragraph_format
            pf.alignment = WD_ALIGN_PARAGRAPH.LEFT
            pf.first_line_indent = Cm(0)
            pf.line_spacing = 1.2
            pf.space_before = Pt(before)
            pf.space_after = Pt(after)
            pf.keep_with_next = True
            ppr = style.element.get_or_add_pPr()
            if ppr.find(qn("w:outlineLvl")) is None:
                lvl = OxmlElement("w:outlineLvl")
                lvl.set(qn("w:val"), str(int(name[-1]) - 1))
                ppr.append(lvl)

        for name in ("List Bullet", "List Bullet 2", "List Number"):
            if name in styles:
                _set_style_font(styles[name], 13)

    def _setup_header_footer(self):
        section = self.doc.sections[0]
        header = section.header
        p = header.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        p.paragraph_format.space_after = Pt(2)
        run = p.add_run("Đề cương chi tiết dự án cuối kỳ – Nhóm 03 – Lớp 65KTPM")
        _set_run_font(run, size=9, italic=True)
        _bottom_border(p, sz=4)

        footer = section.footer
        fp = footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = fp.add_run("Trang ")
        _set_run_font(run, size=10)
        _add_field(fp, "PAGE", "1", size=10)

    # ----------------------------------------------------------------- cover
    def add_cover(self, members):
        def line(text, size=14, bold=True, after=2, before=0):
            p = self.doc.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.first_line_indent = Cm(0)
            p.paragraph_format.space_before = Pt(before)
            p.paragraph_format.space_after = Pt(after)
            p.paragraph_format.line_spacing = 1.15
            run = p.add_run(text)
            _set_run_font(run, size=size, bold=bold)

        line("TRƯỜNG ĐẠI HỌC ....................................", 14, True, 2)
        line("KHOA CÔNG NGHỆ THÔNG TIN", 14, True, 4)
        rule = self.doc.add_paragraph()
        rule.paragraph_format.space_after = Pt(18)
        _bottom_border(rule, sz=12)

        line("ĐỀ CƯƠNG CHI TIẾT", 20, True, 2, 8)
        line("DỰ ÁN CUỐI KỲ", 20, True, 16, 0)

        p = self.doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.first_line_indent = Cm(0)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.line_spacing = 1.15
        run = p.add_run("Tên đề tài:")
        _set_run_font(run, size=14, italic=True)

        p = self.doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.first_line_indent = Cm(0)
        p.paragraph_format.space_after = Pt(14)
        p.paragraph_format.line_spacing = 1.15
        run = p.add_run("XÂY DỰNG ỨNG DỤNG QUẢN LÝ TÀI LIỆU HỌC TẬP\nTRÊN NỀN TẢNG DI ĐỘNG")
        _set_run_font(run, size=16.5, bold=True)

        info = [
            ("Học phần", "Phát triển ứng dụng di động"),
            ("Nhóm thực hiện", "Nhóm 03 – Lớp 65KTPM"),
            ("Giảng viên hướng dẫn", "............................................................"),
            ("Thời gian thực hiện", "16/11/2026 – 10/01/2027"),
        ]
        table = self.doc.add_table(rows=0, cols=2)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        table.autofit = False
        for label, value in info:
            row = table.add_row()
            row.height = Cm(0.68)
            for idx, text in enumerate((label, value)):
                cell = row.cells[idx]
                cell.width = Cm(5.2 if idx == 0 else 9.8)
                cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
                _set_cell_margins(cell, 10, 60, 10, 60)
                p = cell.paragraphs[0]
                p.paragraph_format.first_line_indent = Cm(0)
                p.paragraph_format.space_after = Pt(0)
                p.alignment = WD_ALIGN_PARAGRAPH.LEFT
                run = p.add_run(text)
                _set_run_font(run, size=12.5, bold=(idx == 0))

        p = self.doc.add_paragraph()
        p.paragraph_format.space_before = Pt(12)
        p.paragraph_format.space_after = Pt(4)
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.first_line_indent = Cm(0)
        run = p.add_run("THÀNH VIÊN THỰC HIỆN")
        _set_run_font(run, size=12, bold=True)

        mt = self.doc.add_table(rows=1, cols=3)
        mt.alignment = WD_TABLE_ALIGNMENT.CENTER
        mt.autofit = False
        widths = [1.2, 5.8, 9.0]
        headers = ["STT", "Họ và tên", "Vai trò"]
        for i, text in enumerate(headers):
            cell = mt.rows[0].cells[i]
            cell.width = Cm(widths[i])
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            _shade_cell(cell, "E7E6E6")
            _set_cell_margins(cell)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.first_line_indent = Cm(0)
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(text)
            _set_run_font(run, size=11, bold=True)
        _set_repeat_header(mt.rows[0])
        for idx, (name, role) in enumerate(members, start=1):
            row = mt.add_row()
            _set_cant_split(row)
            for i, text in enumerate((str(idx), name, role)):
                cell = row.cells[i]
                cell.width = Cm(widths[i])
                cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
                _set_cell_margins(cell)
                p = cell.paragraphs[0]
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER if i == 0 else WD_ALIGN_PARAGRAPH.LEFT
                p.paragraph_format.first_line_indent = Cm(0)
                p.paragraph_format.space_after = Pt(0)
                run = p.add_run(text)
                _set_run_font(run, size=10.5)
        _set_table_borders(mt)

        p = self.doc.add_paragraph()
        p.paragraph_format.space_before = Pt(16)
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.first_line_indent = Cm(0)
        run = p.add_run("Hà Nội, tháng 11 năm 2026")
        _set_run_font(run, size=12.5)

        self.page_break()

    # -------------------------------------------------------------------- toc
    def add_toc(self):
        p = self.doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.first_line_indent = Cm(0)
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(14)
        run = p.add_run("MỤC LỤC")
        _set_run_font(run, size=16, bold=True)

        for text, level in self.toc_entries:
            p = self.doc.add_paragraph()
            p.paragraph_format.first_line_indent = Cm(0)
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(3)
            p.paragraph_format.line_spacing = 1.1
            indent = 0.75 if level == 1 else 0.0
            p.paragraph_format.left_indent = Cm(indent)
            tab_pos = Cm(TEXT_WIDTH_CM - indent)
            p.paragraph_format.tab_stops.add_tab_stop(
                tab_pos, WD_TAB_ALIGNMENT.RIGHT, WD_TAB_LEADER.DOTS
            )
            page = self.toc_pages.get(text, "00")
            run = p.add_run(f"{text}\t{page}")
            _set_run_font(run, size=12, bold=(level == 0))
        self.page_break()

    # --------------------------------------------------------------- headings
    def h1(self, text, page_break=True):
        p = self.doc.add_paragraph(style="Heading 1")
        p.paragraph_format.page_break_before = page_break
        p.paragraph_format.first_line_indent = Cm(0)
        run = p.add_run(text)
        _set_run_font(run, size=16, bold=True)
        return p

    def h2(self, text):
        p = self.doc.add_paragraph(style="Heading 2")
        p.paragraph_format.first_line_indent = Cm(0)
        run = p.add_run(text)
        _set_run_font(run, size=14, bold=True)
        return p

    def h3(self, text):
        p = self.doc.add_paragraph(style="Heading 3")
        p.paragraph_format.first_line_indent = Cm(0)
        run = p.add_run(text)
        _set_run_font(run, size=13, bold=True, italic=True)
        return p

    # --------------------------------------------------------------- body text
    def p(self, text, bold_prefix=None, italic=False, align="justify", indent=True):
        p = self.doc.add_paragraph()
        p.paragraph_format.first_line_indent = Cm(1.0) if indent else Cm(0)
        p.paragraph_format.line_spacing = 1.5
        p.paragraph_format.space_after = Pt(6)
        p.alignment = {
            "justify": WD_ALIGN_PARAGRAPH.JUSTIFY,
            "left": WD_ALIGN_PARAGRAPH.LEFT,
            "center": WD_ALIGN_PARAGRAPH.CENTER,
        }[align]
        if bold_prefix:
            run = p.add_run(bold_prefix)
            _set_run_font(run, size=13, bold=True, italic=italic)
        run = p.add_run(text)
        _set_run_font(run, size=13, italic=italic)
        return p

    def bullet(self, text, level=1, bold_prefix=None):
        p = self.doc.add_paragraph()
        p.paragraph_format.first_line_indent = Cm(-0.55)
        p.paragraph_format.left_indent = Cm(0.75 + (level - 1) * 0.7)
        p.paragraph_format.line_spacing = 1.4
        p.paragraph_format.space_after = Pt(3)
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        p.paragraph_format.tab_stops.add_tab_stop(Cm(0.75 + (level - 1) * 0.7))
        mark = "•" if level == 1 else "–"
        run = p.add_run(f"{mark}\t")
        _set_run_font(run, size=13)
        if bold_prefix:
            run = p.add_run(bold_prefix)
            _set_run_font(run, size=13, bold=True)
        run = p.add_run(text)
        _set_run_font(run, size=13)
        return p

    def numbered(self, number, text, bold_prefix=None):
        p = self.doc.add_paragraph()
        p.paragraph_format.first_line_indent = Cm(-0.65)
        p.paragraph_format.left_indent = Cm(0.95)
        p.paragraph_format.line_spacing = 1.4
        p.paragraph_format.space_after = Pt(3)
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        p.paragraph_format.tab_stops.add_tab_stop(Cm(0.95))
        run = p.add_run(f"{number}.\t")
        _set_run_font(run, size=13)
        if bold_prefix:
            run = p.add_run(bold_prefix)
            _set_run_font(run, size=13, bold=True)
        run = p.add_run(text)
        _set_run_font(run, size=13)
        return p

    # ------------------------------------------------------------------ table
    def table_caption(self, text):
        self.table_no += 1
        p = self.doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.first_line_indent = Cm(0)
        p.paragraph_format.space_before = Pt(6)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(f"Bảng {self.table_no}. {text}")
        _set_run_font(run, size=11, bold=True)
        return self.table_no

    def table(
        self,
        headers,
        rows,
        widths=None,
        font_size=10.5,
        header_size=10.5,
        align_center=None,
        header_fill="D9D9D9",
        zebra=False,
    ):
        cols = len(headers)
        widths = widths or [TEXT_WIDTH_CM / cols] * cols
        table = self.doc.add_table(rows=1, cols=cols)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        table.autofit = False
        table.allow_autofit = False
        _set_table_borders(table)

        tbl_pr = table._tbl.tblPr
        tbl_w = OxmlElement("w:tblW")
        tbl_w.set(qn("w:w"), str(int(sum(widths) * 567)))
        tbl_w.set(qn("w:type"), "dxa")
        tbl_pr.append(tbl_w)
        layout = OxmlElement("w:tblLayout")
        layout.set(qn("w:type"), "fixed")
        tbl_pr.append(layout)

        align_center = align_center or []
        header = table.rows[0]
        _set_repeat_header(header)
        _set_cant_split(header)
        for i, text in enumerate(headers):
            cell = header.cells[i]
            cell.width = Cm(widths[i])
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            _shade_cell(cell, header_fill)
            _set_cell_margins(cell)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.first_line_indent = Cm(0)
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.0
            run = p.add_run(str(text))
            _set_run_font(run, size=header_size, bold=True)

        for r_idx, row_data in enumerate(rows):
            row = table.add_row()
            _set_cant_split(row)
            for c_idx, value in enumerate(row_data):
                cell = row.cells[c_idx]
                cell.width = Cm(widths[c_idx])
                cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
                _set_cell_margins(cell)
                if zebra and r_idx % 2 == 1:
                    _shade_cell(cell, "F2F2F2")
                lines = str(value).split("\n")
                for l_idx, line in enumerate(lines):
                    p = cell.paragraphs[0] if l_idx == 0 else cell.add_paragraph()
                    p.paragraph_format.first_line_indent = Cm(0)
                    p.paragraph_format.space_before = Pt(0)
                    p.paragraph_format.space_after = Pt(0)
                    p.paragraph_format.line_spacing = 1.05
                    p.alignment = (
                        WD_ALIGN_PARAGRAPH.CENTER
                        if c_idx in align_center
                        else WD_ALIGN_PARAGRAPH.LEFT
                    )
                    run = p.add_run(line)
                    _set_run_font(run, size=font_size)
        # khoảng cách sau bảng
        spacer = self.doc.add_paragraph()
        spacer.paragraph_format.space_before = Pt(0)
        spacer.paragraph_format.space_after = Pt(2)
        spacer.paragraph_format.line_spacing = 0.6
        return table

    # ----------------------------------------------------------------- figure
    def figure(self, path: str | Path, caption: str, width_cm=15.0):
        self.figure_no += 1
        p = self.doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.first_line_indent = Cm(0)
        p.paragraph_format.space_before = Pt(6)
        p.paragraph_format.space_after = Pt(3)
        p.paragraph_format.keep_with_next = True
        run = p.add_run()
        run.add_picture(str(path), width=Cm(width_cm))
        cap = self.doc.add_paragraph()
        cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        cap.paragraph_format.first_line_indent = Cm(0)
        cap.paragraph_format.space_before = Pt(0)
        cap.paragraph_format.space_after = Pt(10)
        run = cap.add_run(f"Hình {self.figure_no}. {caption}")
        _set_run_font(run, size=11, italic=True)

    def page_break(self):
        self.doc.add_page_break()

    def save(self, path: str | Path):
        props = self.doc.core_properties
        props.title = "Đề cương chi tiết dự án cuối kỳ – Ứng dụng Quản lý Tài liệu Học tập"
        props.subject = "Đề cương Project cuối kỳ học phần Phát triển ứng dụng di động"
        props.author = "Nhóm 03 – Lớp 65KTPM"
        props.keywords = "đề cương, quản lý tài liệu, Flutter, Supabase, Firebase"
        props.comments = "Tài liệu học thuật, trình bày đen trắng, khổ A4."
        settings = self.doc.settings.element
        update = OxmlElement("w:updateFields")
        update.set(qn("w:val"), "true")
        settings.append(update)
        self.doc.save(str(path))
