/// ARPAbet phoneme data: pronunciation dictionary, fallback letter-to-sound
/// rules, IPA display and phoneme similarity used for weighted alignment.
library;

// Subset of CMUdict (stress removed) covering all lesson words plus the
// words speech recognizers typically return for mispronounced lesson words.
const Map<String, String> _dict = {
  'a': 'AH', 'and': 'AE N D', 'are': 'AA R', 'bag': 'B AE G', 'ban': 'B AE N',
  'bat': 'B AE T', 'berry': 'B EH R IY', 'best': 'B EH S T', 'bet': 'B EH T',
  'book': 'B UH K', 'books': 'B UH K S', 'cat': 'K AE T', 'cats': 'K AE T S',
  'coffee': 'K AO F IY', 'cup': 'K AH P', 'dat': 'D AE T', 'dis': 'D IH S',
  'dog': 'D AO G', 'dogs': 'D AO G Z', 'eat': 'IY T', 'enough': 'IH N AH F',
  'fan': 'F AE N', 'feel': 'F IY L', 'fill': 'F IH L', 'for': 'F AO R',
  'free': 'F R IY', 'how': 'HH AW', 'i': 'AY', "i'm": 'AY M', 'in': 'IH N',
  'is': 'IH Z', 'it': 'IH T', "it's": 'IH T S', 'lead': 'L IY D', 'leave': 'L IY V',
  'led': 'L EH D', 'lice': 'L AY S', 'light': 'L AY T', 'like': 'L AY K',
  'likes': 'L AY K S', 'live': 'L IH V', 'load': 'L OW D', 'lorry': 'L AO R IY',
  'me': 'M IY', 'meet': 'M IY T', 'mother': 'M AH DH ER', 'mouth': 'M AW TH',
  'my': 'M AY', 'nice': 'N AY S', 'of': 'AH V', 'play': 'P L EY',
  'played': 'P L EY D', 'please': 'P L IY Z', 'red': 'R EH D', 'rice': 'R AY S',
  'right': 'R AY T', 'road': 'R OW D', 'sank': 'S AE NG K', 'sea': 'S IY',
  'seat': 'S IY T', 'see': 'S IY', 'sell': 'S EH L', 'sells': 'S EH L Z',
  'shall': 'SH AE L', 'she': 'SH IY', 'sheep': 'SH IY P', 'shell': 'SH EH L',
  'shells': 'SH EH L Z', 'ship': 'SH IH P', 'sin': 'S IH N', 'sink': 'S IH NG K',
  'sip': 'S IH P', 'sit': 'S IH T', 'tank': 'T AE NG K', 'tanks': 'T AE NG K S',
  'tea': 'T IY', 'thank': 'TH AE NG K', 'thanks': 'TH AE NG K S', 'that': 'DH AE T',
  'the': 'DH AH', 'there': 'DH EH R', 'think': 'TH IH NG K', 'this': 'DH IH S',
  'three': 'TH R IY', 'time': 'T AY M', 'to': 'T UW', 'today': 'T AH D EY',
  'tree': 'T R IY', 'van': 'V AE N', 'very': 'V EH R IY', 'vest': 'V EH S T',
  'villages': 'V IH L IH JH IH Z', 'vine': 'V AY N', 'visit': 'V IH Z IH T',
  'warm': 'W AO R M', 'we': 'W IY', 'weather': 'W EH DH ER', 'west': 'W EH S T',
  'wet': 'W EH T', 'what': 'W AH T', 'wine': 'W AY N', 'would': 'W UH D',
  'wood': 'W UH D', 'you': 'Y UW', 'zat': 'Z AE T', 'zis': 'Z IH S',
  'one': 'W AH N', 'two': 'T UW', 'four': 'F AO R', 'five': 'F AY V',
  'six': 'S IH K S', 'seven': 'S EH V AH N', 'eight': 'EY T', 'nine': 'N AY N',
  'ten': 'T EH N', 'zero': 'Z IH R OW',
};

const _digits = [
  'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
];

/// Lowercases, strips punctuation and spells out small numbers, since
/// recognizers often return "3" for "three".
List<String> tokenize(String text) {
  final out = <String>[];
  for (final raw in text.toLowerCase().split(RegExp(r'\s+'))) {
    final w = raw.replaceAll(RegExp(r"[^a-z0-9']"), '');
    if (w.isEmpty) continue;
    final n = int.tryParse(w);
    out.add(n != null && n >= 0 && n <= 10 ? _digits[n] : w);
  }
  return out;
}

bool inDictionary(String word) => _dict.containsKey(word);

/// Dictionary lookup with a rule-based fallback.
List<String> phonemesOf(String word) {
  final hit = _dict[word];
  if (hit != null) return hit.split(' ');
  return _letterToSound(word);
}

// shortcut: crude grapheme-to-phoneme rules for out-of-dictionary words;
// upgrade to full CMUdict asset or a G2P model if vocabulary grows.
const _rules = <String, String>{
  'tch': 'CH', 'igh': 'AY', 'th': 'TH', 'sh': 'SH', 'ch': 'CH', 'ng': 'NG',
  'ph': 'F', 'ck': 'K', 'wh': 'W', 'qu': 'K W', 'ee': 'IY', 'ea': 'IY',
  'oo': 'UW', 'ai': 'EY', 'ay': 'EY', 'oa': 'OW', 'ow': 'OW', 'ou': 'AW',
  'oi': 'OY', 'oy': 'OY', 'er': 'ER', 'ir': 'ER', 'ur': 'ER', 'ar': 'AA R',
  'or': 'AO R', 'a': 'AE', 'b': 'B', 'c': 'K', 'd': 'D', 'e': 'EH', 'f': 'F',
  'g': 'G', 'h': 'HH', 'i': 'IH', 'j': 'JH', 'k': 'K', 'l': 'L', 'm': 'M',
  'n': 'N', 'o': 'AA', 'p': 'P', 'r': 'R', 's': 'S', 't': 'T', 'u': 'AH',
  'v': 'V', 'w': 'W', 'x': 'K S', 'y': 'Y', 'z': 'Z',
};

List<String> _letterToSound(String word) {
  var w = word.replaceAll("'", '');
  // Silent final e ("make") and doubled consonants.
  if (w.length > 2 && w.endsWith('e') && !w.endsWith('ee')) {
    w = w.substring(0, w.length - 1);
  }
  final out = <String>[];
  var i = 0;
  while (i < w.length) {
    var matched = false;
    for (final len in [3, 2, 1]) {
      if (i + len > w.length) continue;
      final p = _rules[w.substring(i, i + len)];
      if (p == null) continue;
      final ps = p.split(' ');
      if (out.isEmpty || len > 1 || out.last != ps.first) out.addAll(ps);
      i += len;
      matched = true;
      break;
    }
    if (!matched) i++;
  }
  return out;
}

const _ipa = {
  'AA': 'ɑ', 'AE': 'æ', 'AH': 'ʌ', 'AO': 'ɔ', 'AW': 'aʊ', 'AY': 'aɪ', 'B': 'b',
  'CH': 'tʃ', 'D': 'd', 'DH': 'ð', 'EH': 'e', 'ER': 'ɜr', 'EY': 'eɪ', 'F': 'f',
  'G': 'g', 'HH': 'h', 'IH': 'ɪ', 'IY': 'iː', 'JH': 'dʒ', 'K': 'k', 'L': 'l',
  'M': 'm', 'N': 'n', 'NG': 'ŋ', 'OW': 'oʊ', 'OY': 'ɔɪ', 'P': 'p', 'R': 'r',
  'S': 's', 'SH': 'ʃ', 'T': 't', 'TH': 'θ', 'UH': 'ʊ', 'UW': 'uː', 'V': 'v',
  'W': 'w', 'Y': 'j', 'Z': 'z', 'ZH': 'ʒ',
};

String ipa(String phoneme) => _ipa[phoneme] ?? phoneme.toLowerCase();

String ipaOfText(String text) =>
    '/${tokenize(text).map((w) => phonemesOf(w).map(ipa).join()).join(' ')}/';

// Groups of acoustically close phonemes; confusing them costs half an error.
const _similar = [
  {'TH', 'T', 'S', 'F'}, {'DH', 'D', 'Z', 'V'}, {'V', 'W', 'B', 'F'},
  {'R', 'L', 'W'}, {'IY', 'IH'}, {'UW', 'UH'}, {'AE', 'EH', 'AH'},
  {'S', 'SH', 'Z'}, {'CH', 'SH', 'JH'}, {'N', 'NG', 'M'}, {'D', 'T'},
  {'G', 'K'}, {'B', 'P'}, {'AA', 'AO', 'AH'}, {'OW', 'AO'}, {'ER', 'AH'},
];

double substitutionCost(String a, String b) {
  if (a == b) return 0;
  return _similar.any((g) => g.contains(a) && g.contains(b)) ? 0.5 : 1;
}
