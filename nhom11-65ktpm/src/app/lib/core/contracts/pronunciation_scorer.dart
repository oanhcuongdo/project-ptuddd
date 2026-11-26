import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_implementation.dart';
import 'models/pronunciation.dart';

/// Chấm phát âm. Chủ sở hữu: **Khánh** (#13 offline, #14 online + tự chuyển).
///
/// Màn hình (#15) chỉ gọi [assess]; việc chọn online hay offline nằm trong bản thật.
abstract class PronunciationScorer {
  Future<PronunciationResult> assess({
    required String referenceHanzi,
    required String referencePinyin,
    Recording? recording,
    String? recognizedPinyin,
    String? recognizedText,
  });
}

final pronunciationScorerProvider = Provider<PronunciationScorer>((ref) => FakePronunciationScorer());

/// Cài đặt chế độ chấm. Màn Cài đặt của **Đệ** (#24) đổi và lưu giá trị;
/// bộ chấm kết hợp của **Khánh** (#14) đọc `ref.watch(scoringModeProvider)`.
enum ScoringMode { preferOnline, offlineOnly }

final scoringModeProvider = NotifierProvider<ScoringModeNotifier, ScoringMode>(ScoringModeNotifier.new);

class ScoringModeNotifier extends Notifier<ScoringMode> {
  @override
  ScoringMode build() => ScoringMode.preferOnline; // #24: đọc giá trị đã lưu trên máy

  void set(ScoringMode mode) => state = mode;
}

/// Bản giả: điểm cố định theo câu mẫu (cùng câu → cùng kết quả), có đủ 3 màu
/// xanh / vàng / đỏ và đủ loại lỗi để dựng màn phản hồi.
class FakePronunciationScorer with FakeImplementation implements PronunciationScorer {
  @override
  Future<PronunciationResult> assess({
    required String referenceHanzi,
    required String referencePinyin,
    Recording? recording,
    String? recognizedPinyin,
    String? recognizedText,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600)); // giả độ trễ chấm
    final chars = referenceHanzi.runes.map(String.fromCharCode).where((c) => RegExp(r'[一-鿿]').hasMatch(c)).toList();
    final syls = referencePinyin.trim().split(RegExp(r'\s+'));
    final seed = referenceHanzi.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff);
    final out = <SyllableScore>[];
    for (var i = 0; i < chars.length; i++) {
      final expected = splitPinyin(i < syls.length ? syls[i] : '');
      final roll = (seed >> (i % 16)) % 10;
      if (roll < 6) {
        out.add(SyllableScore(hanzi: chars[i], expected: expected, actual: expected, score: 92.0 + roll, status: SyllableStatus.ok));
      } else if (roll < 8) {
        final wrongTone = expected.tone == 2 ? 3 : 2; // lỗi hay gặp: nhầm thanh 2 / 3
        out.add(SyllableScore(
          hanzi: chars[i],
          expected: expected,
          actual: SyllableParts(initial: expected.initial, finalPart: expected.finalPart, tone: wrongTone),
          score: 72,
          status: SyllableStatus.warn,
          errors: const [PronunciationError.tone],
        ));
      } else {
        const swap = {'zh': 'z', 'ch': 'c', 'sh': 's', 'z': 'zh', 'c': 'ch', 's': 'sh', 'j': 'q', 'q': 'j', 'x': 's'};
        out.add(SyllableScore(
          hanzi: chars[i],
          expected: expected,
          actual: SyllableParts(initial: swap[expected.initial] ?? 'l', finalPart: expected.finalPart, tone: expected.tone),
          score: 45,
          status: SyllableStatus.error,
          errors: const [PronunciationError.initial],
        ));
      }
    }
    double avg(Iterable<double> xs) => xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
    final accuracy = avg(out.map((s) => s.score));
    final tone = avg(out.map((s) => s.errors.contains(PronunciationError.tone) ? 60.0 : 95.0));
    return PronunciationResult(
      overall: ((accuracy * 0.5 + tone * 0.3 + 90 * 0.2)).roundToDouble(),
      accuracy: accuracy.roundToDouble(),
      tone: tone.roundToDouble(),
      fluency: 90,
      completeness: 100,
      source: ScoringSource.offline,
      recognizedText: referenceHanzi,
      syllables: out,
    );
  }
}

const _initials = ['zh', 'ch', 'sh', 'b', 'p', 'm', 'f', 'd', 't', 'n', 'l', 'g', 'k', 'h', 'j', 'q', 'x', 'r', 'z', 'c', 's', 'y', 'w'];
const _toneMap = {
  'āēīōūǖ': 1,
  'áéíóúǘ': 2,
  'ǎěǐǒǔǚ': 3,
  'àèìòùǜ': 4,
};
const _plainMap = {
  'āáǎà': 'a', 'ēéěè': 'e', 'īíǐì': 'i', 'ōóǒò': 'o', 'ūúǔù': 'u', 'ǖǘǚǜ': 'ü',
};

/// Tách một âm tiết pinyin có dấu hoặc số: "hǎo" → (h, ao, 3), "ni2" → (n, i, 2).
SyllableParts splitPinyin(String syllable) {
  var s = syllable.trim().toLowerCase();
  var tone = 5;

  final numMatch = RegExp(r'([1-5])$').firstMatch(s);
  if (numMatch != null) {
    tone = int.parse(numMatch.group(1)!);
    s = s.substring(0, s.length - 1);
  }

  final buf = StringBuffer();
  for (final ch in s.split('')) {
    var replaced = ch;
    if (tone == 5) {
      _toneMap.forEach((marks, t) {
        if (marks.contains(ch)) {
          tone = t;
        }
      });
    }
    _plainMap.forEach((marks, p) {
      if (marks.contains(ch)) {
        replaced = p;
      }
    });
    buf.write(replaced);
  }

  s = buf.toString().replaceAll(RegExp(r'[^a-zü]'), '');

  for (final i in _initials) {
    if (s.startsWith(i) && s.length > i.length) {
      return SyllableParts(initial: i, finalPart: s.substring(i.length), tone: tone);
    }
  }
  return SyllableParts(initial: '', finalPart: s, tone: tone);
}

/// Mẹo phát âm (khẩu hình, vị trí lưỡi). Dữ liệu: **Hoa** (#22) trong
/// `assets/data/pronunciation_tips.json`; màn phản hồi của Khánh (#15) đọc qua đây.
class PronunciationTip {
  final String sound; // "zh", "ü", "tone3"...
  final String title;
  final String mouthVi;
  final String tongueVi;
  final String compareVi;
  final List<String> examples;

  const PronunciationTip({
    required this.sound,
    required this.title,
    required this.mouthVi,
    required this.tongueVi,
    required this.compareVi,
    this.examples = const [],
  });

  factory PronunciationTip.fromJson(Map<String, dynamic> j) => PronunciationTip(
    sound: j['sound'] as String,
    title: j['title'] as String,
    mouthVi: j['mouthVi'] as String? ?? '',
    tongueVi: j['tongueVi'] as String? ?? '',
    compareVi: j['compareVi'] as String? ?? '',
    examples: [for (final e in (j['examples'] as List? ?? const [])) e as String],
  );
}

final pronunciationTipsProvider = FutureProvider<Map<String, PronunciationTip>>((ref) async {
  final raw = jsonDecode(await rootBundle.loadString('assets/data/pronunciation_tips.json')) as Map<String, dynamic>;
  return {
    for (final t in (raw['tips'] as List)) (t as Map<String, dynamic>)['sound'] as String: PronunciationTip.fromJson(t),
  };
});
