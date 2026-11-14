import 'pronunciation_scorer.dart';

class Suggestion {
  final String title;
  final String tip;
  final List<String> practiceWords;
  final String lessonId;

  const Suggestion(this.title, this.tip, this.practiceWords, this.lessonId);
}

const _byPhoneme = <String, Suggestion>{
  'TH': Suggestion('Âm /θ/ (think)',
      'Đặt đầu lưỡi giữa hai hàm răng, thổi hơi nhẹ, không rung thanh quản. Đừng đọc thành /t/ hay /s/.',
      ['think – sink', 'three – tree', 'thank – tank'], 'th'),
  'DH': Suggestion('Âm /ð/ (this)',
      'Giống /θ/ nhưng rung thanh quản. Đừng đọc thành /d/ hay /z/.',
      ['this – dis', 'that – dat', 'they – day'], 'th'),
  'V': Suggestion('Âm /v/ (very)',
      'Răng trên chạm nhẹ môi dưới, rung thanh quản. Không tròn môi như /w/.',
      ['very – berry', 'vine – wine', 'vest – west'], 'vw'),
  'W': Suggestion('Âm /w/ (west)',
      'Tròn môi như khi nói "u", rồi mở nhanh. Răng không chạm môi.',
      ['west – vest', 'wine – vine', 'wet – vet'], 'vw'),
  'R': Suggestion('Âm /r/ (right)',
      'Cong đầu lưỡi về sau, không chạm vòm miệng, môi hơi tròn.',
      ['right – light', 'road – load', 'rice – lice'], 'rl'),
  'L': Suggestion('Âm /l/ (light)',
      'Đầu lưỡi chạm lợi sau răng cửa trên, hơi thoát hai bên lưỡi.',
      ['light – right', 'load – road', 'led – red'], 'rl'),
  'IY': Suggestion('Nguyên âm /iː/ (sheep)',
      'Kéo dài âm, căng môi như đang cười.',
      ['sheep – ship', 'leave – live', 'seat – sit'], 'ii'),
  'IH': Suggestion('Nguyên âm /ɪ/ (ship)',
      'Âm ngắn, thả lỏng môi, miệng hơi mở hơn /iː/.',
      ['ship – sheep', 'live – leave', 'sit – seat'], 'ii'),
  'SH': Suggestion('Âm /ʃ/ (she)',
      'Tròn môi đưa ra trước, lưỡi lùi về sau, thổi hơi "suỵt".',
      ['she – see', 'shell – sell', 'ship – sip'], 'ssh'),
  'S': Suggestion('Âm /s/ (see)',
      'Hai hàm răng khép, môi bẹt, thổi hơi qua đầu lưỡi.',
      ['see – she', 'sell – shell', 'sip – ship'], 'ssh'),
};

const _finalConsonant = Suggestion('Phụ âm cuối',
    'Bạn đang nuốt âm cuối. Kết thúc từ bằng cách bật rõ phụ âm, đặc biệt /s/, /z/ ở số nhiều và /d/, /t/ ở quá khứ.',
    ['cat – cats', 'play – played', 'dog – dogs'], 'final');

const _generic = Suggestion('Luyện nghe – nhắc lại',
    'Nhấn "Nghe mẫu", nói chậm từng từ rồi tăng dần tốc độ.',
    [], 'daily');

/// Turns phoneme errors into at most [max] distinct, prioritized suggestions.
List<Suggestion> suggestionsFor(PronunciationResult r, {int max = 3}) {
  final out = <Suggestion>[];
  void add(Suggestion s) {
    if (!out.contains(s) && out.length < max) out.add(s);
  }

  for (final e in r.errors) {
    if (e.type == ErrorType.deletion && e.atWordEnd) {
      add(_finalConsonant);
    } else if (e.expected != null && _byPhoneme[e.expected] != null) {
      add(_byPhoneme[e.expected]!);
    }
  }
  if (out.isEmpty && r.score < 90) add(_generic);
  return out;
}

String verdict(int score) => switch (score) {
      >= 90 => 'Xuất sắc!',
      >= 75 => 'Tốt, gần chuẩn rồi',
      >= 50 => 'Khá, cần luyện thêm',
      _ => 'Hãy thử lại chậm hơn',
    };
