import '../scoring/pronunciation_scorer.dart';

/// Chuyển các lượt nói (hàng của bảng attempts) thành CSV để dán vào bảng
/// kiểm thử trong báo cáo. Lỗi âm vị được chấm lại offline từ văn bản đã lưu.
String attemptsToCsv(List<Map<String, Object?>> rows) {
  String q(Object? v) {
    final s = '$v';
    return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  final b = StringBuffer('Thời gian,Câu mẫu,Nghe được,Điểm,Độ tin cậy,Lỗi âm vị\n');
  for (final r in rows) {
    final errors = scorePronunciation(r['expected_text'] as String, r['recognized_text'] as String,
            confidence: (r['confidence'] as num).toDouble())
        .errors
        .map((e) => '${e.word}: ${e.describe}')
        .join('; ');
    b.writeln([
      r['created_at'],
      r['expected_text'],
      r['recognized_text'],
      r['score'],
      (r['confidence'] as num).toStringAsFixed(2),
      errors,
    ].map(q).join(','));
  }
  return b.toString();
}
