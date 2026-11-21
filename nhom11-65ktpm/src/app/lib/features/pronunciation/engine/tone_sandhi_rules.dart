import 'pinyin_tone_helper.dart';
import 'text_normalizer_zh.dart';

class ToneSandhiRules {
  static List<String> applyToneSandhi(List<String> hanziList, List<String> pinyinList) {
    if (hanziList.length != pinyinList.length) return pinyinList;
    final n = hanziList.length;
    final result = List<String>.from(pinyinList);

    // Quy tac 1: Bien dieu 2 thanh 3 lien nhau (3 + 3 -> 2 + 3)
    for (int i = 0; i < n - 1; i++) {
      final toneCurrent = PinyinToneHelper.extractToneNumber(result[i]);
      final toneNext = PinyinToneHelper.extractToneNumber(result[i + 1]);
      if (toneCurrent == 3 && toneNext == 3) {
        final base = PinyinToneHelper.removeTone(result[i]);
        result[i] = PinyinToneHelper.numberToneToMark('${base}2');
      }
    }

    // Quy tac 2: Bien dieu chu '不' (bu4)
    // - Dung truoc thanh 4 thi doc thanh bu2
    // - Dung truoc thanh 1, 2, 3 thi giu nguyen bu4
    // - Dung giua lap lai dong tu doc thanh nhe bu5
    for (int i = 0; i < n; i++) {
      if (hanziList[i] == '不') {
        if (i < n - 1) {
          final nextTone = PinyinToneHelper.extractToneNumber(result[i + 1]);
          if (nextTone == 4) {
            result[i] = 'bú';
          }
        }
      }
    }

    // Quy tac 3: Bien dieu chu '一' (yi1)
    // - Dung truoc thanh 4 thi doc thanh yi2
    // - Dung truoc thanh 1, 2, 3 thi doc thanh yi4
    // - Dung don le, so thu tu giu nguyen yi1
    for (int i = 0; i < n; i++) {
      if (hanziList[i] == '一') {
        if (i < n - 1) {
          final nextTone = PinyinToneHelper.extractToneNumber(result[i + 1]);
          if (nextTone == 4) {
            result[i] = 'yí';
          } else if (nextTone >= 1 && nextTone <= 3) {
            result[i] = 'yì';
          }
        }
      }
    }

    return result;
  }
}
