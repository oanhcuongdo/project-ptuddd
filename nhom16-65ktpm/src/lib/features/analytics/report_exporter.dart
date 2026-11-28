import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/fund_transaction_model.dart';
import 'analytics_service.dart';

/// Dựng nội dung các file báo cáo xuất ra từ màn Thống kê (Giai đoạn 4).
class ReportExporter {
  const ReportExporter();

  /// Nội dung CSV của Sổ Quỹ (C8): dòng tiêu đề cột + mỗi giao dịch
  /// một dòng (cũ nhất trước) + 3 dòng tổng hợp Tổng thu / Tổng chi /
  /// Số dư ở cuối. Dấu tách cột là chấm phẩy ";" vì Excel theo cài
  /// đặt vùng tiếng Việt dùng ";" (dấu phẩy là dấu thập phân) — dùng
  /// dấu phẩy thì file mở ra bị dồn thành một cột. (Không dùng dòng
  /// lệnh "sep=," vì khi có dòng đó Excel bỏ qua BOM UTF-8 và đọc
  /// theo bảng mã ANSI, làm vỡ dấu tiếng Việt.) Mọi ô đều bọc trong
  /// dấu nháy kép và nháy kép bên trong được gấp đôi, nên nội dung
  /// chứa dấu chấm phẩy không làm vỡ cột. Số tiền ghi dạng số thô
  /// để Excel tính được.
  String buildCsv(List<FundTransactionModel> txs) {
    String cell(Object? value) =>
        '"${(value?.toString() ?? '').replaceAll('"', '""')}"';
    String amount(double v) =>
        v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final sorted = [...txs]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    const service = AnalyticsService();

    final rows = <String>[
      'Ngày;Loại;Danh mục;Nội dung;Số tiền (đ);Người / Nhà tài trợ;Ghi chú',
      for (final tx in sorted)
        [
          cell(dateFormat.format(tx.createdAt)),
          cell(tx.isIncome ? 'Thu' : 'Chi'),
          cell(tx.category),
          cell(tx.title),
          cell(amount(tx.amount)),
          cell(tx.recipientOrSponsor),
          cell(tx.note),
        ].join(';'),
      '',
      [
        '',
        '',
        '',
        cell('Tổng thu'),
        cell(amount(service.totalIncome(txs))),
        '',
        '',
      ].join(';'),
      [
        '',
        '',
        '',
        cell('Tổng chi'),
        cell(amount(service.totalExpense(txs))),
        '',
        '',
      ].join(';'),
      [
        '',
        '',
        '',
        cell('Số dư'),
        cell(amount(service.balance(txs))),
        '',
        '',
      ].join(';'),
    ];
    return '${rows.join('\r\n')}\r\n';
  }

  /// File PDF báo cáo quỹ (C9): trang A4 gồm tiêu đề, 3 số tổng hợp
  /// và bảng giao dịch 6 cột có kẻ border (bỏ cột Ghi chú cho vừa
  /// trang; bản CSV vẫn đủ 7 cột). Font Arial nạp từ assets vì font
  /// mặc định của thư viện PDF không hiển thị được tiếng Việt.
  Future<Uint8List> buildPdf(List<FundTransactionModel> txs) async {
    final regularData = await rootBundle.load('assets/fonts/arial.ttf');
    final boldData = await rootBundle.load('assets/fonts/arialbd.ttf');
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(regularData),
        bold: pw.Font.ttf(boldData),
      ),
    );

    const service = AnalyticsService();
    final money = NumberFormat.decimalPattern('vi_VN');
    String amount(double v) => '${money.format(v.round())} đ';
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final sorted = [...txs]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    pw.Widget cell(
      String text, {
      bool bold = false,
      pw.Alignment alignment = pw.Alignment.centerLeft,
    }) {
      return pw.Container(
        alignment: alignment,
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    pw.Widget summaryLine(String label, double value) {
      return pw.RichText(
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: 11),
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: amount(value)),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'BÁO CÁO QUỸ TỪ THIỆN',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'GoodDeeds Fund — Nhóm 16 · Lớp 65KTPM',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.Center(
            child: pw.Text(
              'Ngày xuất báo cáo: ${dateFormat.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.SizedBox(height: 16),
          summaryLine('Tổng thu', service.totalIncome(txs)),
          pw.SizedBox(height: 2),
          summaryLine('Tổng chi', service.totalExpense(txs)),
          pw.SizedBox(height: 2),
          summaryLine('Số dư hiện tại', service.balance(txs)),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.15),
              1: pw.FlexColumnWidth(0.55),
              2: pw.FlexColumnWidth(1.15),
              3: pw.FlexColumnWidth(1.7),
              4: pw.FlexColumnWidth(0.95),
              5: pw.FlexColumnWidth(1.15),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  cell('Ngày', bold: true),
                  cell('Loại', bold: true, alignment: pw.Alignment.center),
                  cell('Danh mục', bold: true),
                  cell('Nội dung', bold: true),
                  cell(
                    'Số tiền (đ)',
                    bold: true,
                    alignment: pw.Alignment.centerRight,
                  ),
                  cell('Người / Nhà tài trợ', bold: true),
                ],
              ),
              for (final tx in sorted)
                pw.TableRow(
                  children: [
                    cell(dateFormat.format(tx.createdAt)),
                    cell(
                      tx.isIncome ? 'Thu' : 'Chi',
                      alignment: pw.Alignment.center,
                    ),
                    cell(tx.category),
                    cell(tx.title),
                    cell(
                      money.format(tx.amount.round()),
                      alignment: pw.Alignment.centerRight,
                    ),
                    cell(tx.recipientOrSponsor),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }
}
