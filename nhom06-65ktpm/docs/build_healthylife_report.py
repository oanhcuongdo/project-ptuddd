"""Build the HealthyLife proposal from UTF-8 Markdown using the teacher's Word template."""
from copy import deepcopy
from pathlib import Path
import re

from docx import Document
from docx.oxml.ns import qn
from docx.table import Table
from docx.text.paragraph import Paragraph

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / 'HealthyLife_Nhom06_De_cuong.md'
OUTPUT = ROOT / 'HealthyLife_Nhom06_De_cuong.docx'


def replace(paragraph, text):
    if not paragraph.runs:
        paragraph.add_run(text)
    else:
        paragraph.runs[0].text = text
        for run in paragraph.runs[1:]:
            run.text = ''


def build():
    doc = Document(ROOT / 'De_cuong_cuoi_ky.docx')
    original = list(doc.paragraphs)
    templates = {kind: deepcopy(original[index]._p) for kind, index in
                 [('heading', 18), ('subheading', 31), ('body', 19), ('bullet', 35)]}
    assignment = deepcopy(doc.tables[0]._tbl)
    cover = {
        5: 'PHÁT TRIỂN ỨNG DỤNG DI ĐỘNG',
        7: 'Đề tài: HealthyLife - Trợ lý kỷ luật và lối sống lành mạnh',
        9: 'Nhóm sinh viên thực hiện: Nhóm 06 - 65KTPM',
        10: 'Nguyễn Thế Trưởng - 2351170626', 11: 'Phương Văn Đức - 2351170585',
        12: 'Hàn Hoàng Hà - 2051063882', 13: 'Nguyễn Đăng Đại - 2351170578',
        14: '', 17: 'Hà Nội, ngày 15 tháng 11 năm 2026',
    }
    for index, text in cover.items():
        replace(original[index], text)
    keep = [p._p for p in original[:18]]
    for element in list(doc.element.body):
        if element not in keep and element.tag != qn('w:sectPr'):
            doc.element.body.remove(element)

    def paragraph(kind, text):
        element = deepcopy(templates[kind])
        for node in list(element):
            if node.tag in (qn('w:bookmarkStart'), qn('w:bookmarkEnd')):
                element.remove(node)
        # Remove copied paragraph identifiers; Word generates fresh ones when editing.
        for attr in list(element.attrib):
            if attr.endswith('}paraId') or attr.endswith('}textId'):
                del element.attrib[attr]
        doc.element.body.insert(len(doc.element.body) - 1, element)
        p = Paragraph(element, doc._body)
        replace(p, text)
        if text == '1. GIỚI THIỆU ĐỀ TÀI':
            p.paragraph_format.page_break_before = True

    table_lines = []
    started = False
    for line in SOURCE.read_text(encoding='utf-8').splitlines():
        if line.startswith('## 1.'):
            started = True
        if not started or not line.strip():
            continue
        if line.startswith('|'):
            if not re.match(r'^\|[\s|:-]+\|$', line):
                table_lines.append([cell.strip() for cell in line.strip('|').split('|')])
            continue
        if table_lines:
            doc.element.body.insert(len(doc.element.body) - 1, assignment)
            table = Table(assignment, doc._body)
            assert len(table_lines) == 5 and all(len(row) == 4 for row in table_lines)
            for row, values in zip(table.rows, table_lines):
                for cell, value in zip(row.cells, values):
                    replace(cell.paragraphs[0], value)
                    for extra in cell.paragraphs[1:]:
                        cell._tc.remove(extra._p)
            for row in list(table.rows)[5:]:
                table._tbl.remove(row._tr)
            table_lines = []
        if line.startswith('### '):
            paragraph('subheading', line[4:])
        elif line.startswith('## '):
            paragraph('heading', line[3:])
        elif line.startswith('- '):
            paragraph('bullet', line[2:])
        else:
            paragraph('body', line)

    for root in (doc.element, doc.styles.element, doc.part.numbering_part.element):
        for fonts in root.iter(qn('w:rFonts')):
            for attr in list(fonts.attrib):
                if attr.lower().endswith('theme'):
                    del fonts.attrib[attr]
            for slot in ('ascii', 'hAnsi', 'eastAsia', 'cs'):
                fonts.set(qn('w:' + slot), 'Times New Roman')
    doc.core_properties.title = 'Đề cương HealthyLife - Nhóm 06 - 65KTPM'
    doc.core_properties.author = 'Nhóm 06 - 65KTPM'
    doc.core_properties.subject = 'Phát triển ứng dụng di động'
    doc.save(OUTPUT)

    result = Document(OUTPUT)
    text = '\n'.join(t.text or '' for t in result.element.iter(qn('w:t')))
    assert '?' not in text and '\ufffd' not in text, 'Broken Vietnamese encoding'
    assert 'Nguyễn Thế Trưởng' in text and 'PHÁT TRIỂN ỨNG DỤNG DI ĐỘNG' in text
    assert len([p for p in result.paragraphs if p.style.name == 'Heading 1']) == 11
    assert len(result.tables) == 1 and len(result.tables[0].rows) == 5
    template = Document(ROOT / 'De_cuong_cuoi_ky.docx')
    assert result.sections[0]._sectPr.xml == template.sections[0]._sectPr.xml
    print(f'PASS: {OUTPUT.name}; 11 sections, 4 members, Unicode and page settings verified.')


if __name__ == '__main__':
    build()
