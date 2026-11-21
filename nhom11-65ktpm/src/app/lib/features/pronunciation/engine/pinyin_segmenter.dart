import 'pinyin_tone_helper.dart';

class PinyinSegment {
  final String raw;
  final String initial; // Thanh mau (phu am dau)
  final String finalPart; // Van mau
  final int tone; // Thanh dieu (1-5)

  PinyinSegment({
    required this.raw,
    required this.initial,
    required this.finalPart,
    required this.tone,
  });

  @override
  String toString() => '$raw ($initial + $finalPart, tone: $tone)';
}

class PinyinSegmenter {
  static const List<String> _initials = [
    'b', 'p', 'm', 'f',
    'd', 't', 'n', 'l',
    'g', 'k', 'h',
    'j', 'q', 'x',
    'zh', 'ch', 'sh', 'r',
    'z', 'c', 's',
    'y', 'w',
  ];

  static PinyinSegment segment(String pinyin) {
    final clean = pinyin.trim().toLowerCase();
    if (clean.isEmpty) {
      return PinyinSegment(raw: '', initial: '', finalPart: '', tone: 5);
    }

    final tone = PinyinToneHelper.extractToneNumber(clean);
    final base = PinyinToneHelper.removeTone(clean);

    String matchedInitial = '';
    // Tim phu am dau dai nhat truoc (zh, ch, sh)
    final sortedInitials = List<String>.from(_initials)..sort((a, b) => b.length.compareTo(a.length));
    for (final init in sortedInitials) {
      if (base.startsWith(init)) {
        matchedInitial = init;
        break;
      }
    }

    final finalPart = base.substring(matchedInitial.length);

    return PinyinSegment(
      raw: clean,
      initial: matchedInitial,
      finalPart: finalPart,
      tone: tone,
    );
  }
}
