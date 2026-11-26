import 'phonemes.dart';

/// Một âm hay sai: [errors] lần sai trên [seen] lần âm đó xuất hiện trong câu mẫu.
class WeakSound {
  final String phoneme;
  final int errors;
  final int seen;
  const WeakSound(this.phoneme, this.errors, this.seen);

  double get rate => errors / seen;
}

/// Xếp các âm theo TỈ LỆ sai (không phải số lần sai thô): âm luyện nhiều lần
/// nhưng sai ít không được xếp trên âm mới luyện vài lần mà sai gần hết.
/// [expectedTexts] là các câu mẫu của những lượt nói đang xét, [errorPhonemes]
/// là âm mẫu bị sai trong các lượt đó. Âm xuất hiện dưới [minSeen] lần bị bỏ
/// qua vì mẫu quá nhỏ.
List<WeakSound> computeWeakSounds(List<String> expectedTexts, List<String> errorPhonemes,
    {int top = 5, int minSeen = 3}) {
  final seen = <String, int>{};
  for (final t in expectedTexts) {
    for (final w in tokenize(t)) {
      for (final p in phonemesOf(w)) {
        seen[p] = (seen[p] ?? 0) + 1;
      }
    }
  }
  final errs = <String, int>{};
  for (final p in errorPhonemes) {
    errs[p] = (errs[p] ?? 0) + 1;
  }
  final out = [
    for (final e in errs.entries)
      if ((seen[e.key] ?? 0) >= minSeen) WeakSound(e.key, e.value, seen[e.key]!),
  ]..sort((a, b) {
      final c = b.rate.compareTo(a.rate);
      if (c != 0) return c;
      final d = b.errors.compareTo(a.errors);
      return d != 0 ? d : a.phoneme.compareTo(b.phoneme); // sort của Dart không ổn định
    });
  return out.take(top).toList();
}
