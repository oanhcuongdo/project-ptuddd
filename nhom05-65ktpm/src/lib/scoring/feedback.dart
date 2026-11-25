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
  'T': Suggestion('Âm /t/ (tea)',
      'Đầu lưỡi chạm lợi trên rồi bật hơi, không đưa lưỡi ra giữa hai hàm răng như /θ/.',
      ['tree – three', 'tank – thank', 'tie – thigh'], 'th'),
  'D': Suggestion('Âm /d/ (day)',
      'Đầu lưỡi chạm lợi trên và rung thanh quản, không đưa lưỡi ra giữa răng như /ð/.',
      ['day – they', 'dare – there', 'den – then'], 'th'),
  'F': Suggestion('Âm /f/ (fan)',
      'Răng trên chạm môi dưới, thổi hơi, không rung thanh quản. Đừng nhầm với /θ/ hay /v/.',
      ['fan – van', 'free – three', 'fine – vine'], 'vw'),
  'Z': Suggestion('Âm /z/ (zoo)',
      'Giống /s/ nhưng rung thanh quản (đặt tay lên cổ để cảm nhận), nhất là ở số nhiều cuối từ.',
      ['zoo – sue', 'buzz – bus', 'peas – peace'], 'ssh'),
  'B': Suggestion('Âm /b/ (berry)',
      'Hai môi mím rồi bật hơi, răng không chạm môi như /v/.',
      ['berry – very', 'boat – vote', 'best – vest'], 'vw'),
  'P': Suggestion('Âm /p/ (pen)',
      'Hai môi mím rồi bật hơi mạnh, không rung thanh quản; đặt tay trước miệng sẽ thấy hơi thoát ra.',
      ['pen – ben', 'pie – buy', 'rope – robe'], 'vw'),
  'CH': Suggestion('Âm /tʃ/ (chip)',
      'Bắt đầu như /t/ rồi trượt sang /ʃ/, môi hơi tròn.',
      ['chip – ship', 'chair – share', 'watch – wash'], 'ssh'),
  'JH': Suggestion('Âm /dʒ/ (jam)',
      'Giống /tʃ/ nhưng rung thanh quản.',
      ['jam – sham', 'joke – choke', 'jeep – cheap'], 'ssh'),
  'N': Suggestion('Âm /n/ (nice)',
      'Đầu lưỡi chạm lợi trên, hơi thoát qua mũi. Ở cuối từ đừng đọc thành /ŋ/.',
      ['sin – sing', 'ban – bang', 'thin – thing'], 'final'),
  'NG': Suggestion('Âm /ŋ/ (sing)',
      'Cuống lưỡi chạm vòm mềm, hơi thoát qua mũi, không bật /g/ ở cuối.',
      ['sing – sin', 'think – thin', 'bang – ban'], 'final'),
  'M': Suggestion('Âm /m/ (me)',
      'Hai môi khép kín, hơi thoát qua mũi; giữ môi khép khi kết thúc từ như "time".',
      ['time – tie', 'some – sun', 'dim – din'], 'final'),
  'G': Suggestion('Âm /g/ (go)',
      'Cuống lưỡi chạm vòm mềm rồi bật hơi, có rung thanh quản.',
      ['bag – back', 'dog – dock', 'pig – pick'], 'final'),
  'K': Suggestion('Âm /k/ (book)',
      'Cuống lưỡi chạm vòm mềm rồi bật hơi, không rung; ở cuối từ vẫn phải bật rõ.',
      ['back – bag', 'book – boo', 'luck – lug'], 'final'),
  'AE': Suggestion('Nguyên âm /æ/ (cat)',
      'Mở miệng rộng, lưỡi thấp; rộng hơn /e/ trong "bet".',
      ['bat – bet', 'man – men', 'bad – bed'], 'vowels'),
  'EH': Suggestion('Nguyên âm /e/ (bet)',
      'Miệng mở vừa, môi hơi bẹt; hẹp hơn /æ/.',
      ['bet – bat', 'men – man', 'bed – bad'], 'vowels'),
  'AH': Suggestion('Nguyên âm /ʌ/ (cup)',
      'Miệng mở vừa, lưỡi thả lỏng ở giữa, âm ngắn gần như "â" tiếng Việt.',
      ['cup – cop', 'luck – lack', 'cut – cat'], 'vowels'),
  'AA': Suggestion('Nguyên âm /ɑ/ (hot)',
      'Miệng mở rộng, lưỡi hạ thấp và lùi về sau, môi không tròn.',
      ['hot – hut', 'box – bucks', 'cop – cup'], 'vowels'),
  'AO': Suggestion('Nguyên âm /ɔ/ (dog)',
      'Môi tròn nhẹ, lưỡi lùi về sau, kéo dài hơn /ɑ/.',
      ['dog – dug', 'law – low', 'caught – coat'], 'vowels'),
  'OW': Suggestion('Nguyên âm /oʊ/ (road)',
      'Bắt đầu từ "ô" rồi tròn môi trượt sang "u", đừng đọc thành một âm đơn.',
      ['road – rod', 'low – law', 'coat – caught'], 'vowels'),
  'ER': Suggestion('Nguyên âm /ɜr/ (bird)',
      'Cong lưỡi về sau như /r/ ngay từ đầu âm, môi hơi tròn.',
      ['bird – bad', 'her – hair', 'work – walk'], 'vowels'),
  'UW': Suggestion('Nguyên âm /uː/ (food)',
      'Tròn môi và kéo dài âm; dài hơn /ʊ/ trong "book".',
      ['food – foot', 'pool – pull', 'fool – full'], 'vowels'),
  'UH': Suggestion('Nguyên âm /ʊ/ (book)',
      'Âm ngắn, môi tròn lỏng, không kéo dài như /uː/.',
      ['foot – food', 'pull – pool', 'full – fool'], 'vowels'),
};

/// Mẹo + cặp từ + bài luyện cho một âm; null nếu chưa có mẹo cho âm đó.
Suggestion? suggestionForPhoneme(String phoneme) => _byPhoneme[phoneme];

const _finalConsonant = Suggestion('Phụ âm cuối',
    'Âm cuối từ chưa rõ (bị nuốt hoặc đọc thành âm khác). Kết thúc từ bằng cách bật rõ phụ âm, đặc biệt /s/, /z/ ở số nhiều và /d/, /t/ ở quá khứ.',
    ['cat – cats', 'play – played', 'dog – dogs'], 'final');

const _generic = Suggestion('Luyện nghe – nhắc lại',
    'Nhấn "Nghe mẫu", nói chậm từng từ rồi tăng dần tốc độ.',
    [], 'daily');

/// Phụ âm cuối hay bị nuốt hoặc đổi (bat → bad); lỗi ở cuối từ dùng mẹo phụ âm cuối.
const _finalStops = {'T', 'D', 'K', 'G', 'S', 'Z', 'P', 'B'};

/// Turns phoneme errors into at most [max] distinct suggestions, ordered by
/// how often each error occurs (ties keep first-seen order).
List<Suggestion> suggestionsFor(PronunciationResult r, {int max = 3}) {
  final count = <Suggestion, int>{}; // LinkedHashMap giữ thứ tự xuất hiện đầu tiên
  for (final e in r.errors) {
    final s = e.atWordEnd && (e.type == ErrorType.deletion || _finalStops.contains(e.expected))
        ? _finalConsonant
        : _byPhoneme[e.expected];
    if (s != null) count[s] = (count[s] ?? 0) + 1;
  }
  final order = count.keys.toList(); // List.sort của Dart không ổn định → tie-break theo vị trí
  final out = [...order]..sort((a, b) {
      final c = count[b]!.compareTo(count[a]!);
      return c != 0 ? c : order.indexOf(a).compareTo(order.indexOf(b));
    });
  if (out.isEmpty && r.score < 90) out.add(_generic);
  return out.take(max).toList();
}

String verdict(int score) => switch (score) {
      >= 90 => 'Xuất sắc!',
      >= 75 => 'Tốt, gần chuẩn rồi',
      >= 50 => 'Khá, cần luyện thêm',
      _ => 'Hãy thử lại chậm hơn',
    };
