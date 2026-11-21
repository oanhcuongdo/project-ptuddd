import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsInitialized = false;

  AudioService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('vi-VN');
      await _flutterTts.setSpeechRate(0.42); // Tốc độ thong thả, rõ từng từ cho trẻ 4-6 tuổi
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.15); // Âm điệu thân thiện, ấm áp

      // Tìm và chọn giọng tiếng Việt (ví dụ Microsoft An trên Windows) nếu có
      try {
        final voices = await _flutterTts.getVoices;
        if (voices is List) {
          for (final voice in voices) {
            if (voice is Map) {
              final locale = (voice['locale'] ?? '').toString().toLowerCase();
              final name = (voice['name'] ?? '').toString().toLowerCase();
              if (locale.contains('vi') || name.contains('vietnam') || name.contains('an')) {
                await _flutterTts.setVoice({
                  'name': voice['name'].toString(),
                  'locale': voice['locale'].toString(),
                });
                break;
              }
            }
          }
        }
      } catch (_) {}

      _isTtsInitialized = true;
    } catch (_) {
      _isTtsInitialized = false;
    }
  }

  /// Chuyển đổi số nguyên (0 đến 99) thành chữ tiếng Việt chuẩn xác
  static String numberToVietnameseWords(int n) {
    if (n < 0) return 'âm ${numberToVietnameseWords(-n)}';
    if (n == 0) return 'không';
    const digits = [
      'không',
      'một',
      'hai',
      'ba',
      'bốn',
      'năm',
      'sáu',
      'bảy',
      'tám',
      'chín'
    ];
    if (n < 10) return digits[n];
    if (n == 10) return 'mười';
    if (n < 20) {
      final unit = n % 10;
      if (unit == 5) return 'mười lăm';
      return 'mười ${digits[unit]}';
    }
    final tens = n ~/ 10;
    final unit = n % 10;
    final tensStr = '${digits[tens]} mươi';
    if (unit == 0) return tensStr;
    if (unit == 1) return '${digits[tens]} mươi mốt';
    if (unit == 4) return '${digits[tens]} mươi tư';
    if (unit == 5) return '${digits[tens]} mươi lăm';
    return '$tensStr ${digits[unit]}';
  }

  /// Chuẩn hóa toàn bộ câu đọc thành tiếng Việt hoàn toàn:
  /// - Chuyển dấu phép tính +, -, =, ? sang chữ tiếng Việt ("cộng", "trừ", "bằng", "bao nhiêu")
  /// - Chuyển mọi con số 0-99 thành chữ tiếng Việt để tránh bị đọc bằng tiếng Anh
  static String normalizeToVietnamese(String text) {
    var result = text;
    // Chuyển các phép toán và ký tự đặc biệt
    result = result.replaceAll('+', ' cộng ');
    result = result.replaceAll('-', ' trừ ');
    result = result.replaceAll('=', ' bằng ');
    result = result.replaceAll('?', ' bao nhiêu ');

    // Chuẩn hóa khoảng trắng trước khi trích xuất số
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Chuyển các số độc lập trong chuỗi sang chữ tiếng Việt
    result = result.replaceAllMapped(RegExp(r'\b\d+\b'), (match) {
      final val = int.tryParse(match.group(0)!);
      if (val != null && val >= 0 && val <= 99) {
        return numberToVietnameseWords(val);
      }
      return match.group(0)!;
    });

    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Phát âm văn bản đã được chuẩn hóa 100% tiếng Việt
  Future<void> speak(String text) async {
    if (!_isTtsInitialized) {
      await _initTts();
    }
    try {
      final normalized = normalizeToVietnamese(text);
      await _flutterTts.speak(normalized);
    } catch (_) {}
  }

  Future<void> playBeadClick() async {
    // Phản hồi rung nhẹ xúc giác ngay lập tức khi gảy ngón tay
    await HapticFeedback.lightImpact();
  }

  /// Lời khen ngợi sinh động khi bé làm chính xác
  Future<void> playSuccessFeedback([String? customPraise]) async {
    await HapticFeedback.mediumImpact();
    const praises = [
      'Hoan hô bé! Bé làm hoàn toàn chính xác! Bé giỏi quá!',
      'Tuyệt vời quá! Bé tính rất nhanh và chuẩn xác!',
      'Xuất sắc! Bé nhớ bài và dùng ngón tay rất siêu!',
      'Chúc mừng bé! Bé đã tính đúng rồi nhé!',
    ];
    final praise = customPraise ?? praises[Random().nextInt(praises.length)];
    await speak(praise);
  }

  /// Lời động viên và đọc hướng dẫn cụ thể khi bé làm sai
  Future<void> playEncouragementFeedback([String? explanation]) async {
    await HapticFeedback.selectionClick();
    if (explanation != null && explanation.trim().isNotEmpty) {
      await speak('Bé đừng buồn nhé! Cùng nghe hướng dẫn nào: $explanation');
    } else {
      await speak('Bé đừng buồn nhé! Cùng xem hướng dẫn để làm lại cho đúng nào!');
    }
  }
}
