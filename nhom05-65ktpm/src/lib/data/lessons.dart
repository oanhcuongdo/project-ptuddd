/// Static lesson content. Each lesson targets sounds Vietnamese learners
/// commonly mispronounce; ids are referenced by the feedback module.
class Lesson {
  final String id;
  final String title;
  final String description;
  final List<String> items;

  const Lesson(this.id, this.title, this.description, this.items);
}

const lessons = <Lesson>[
  Lesson('th', 'Âm /θ/ và /ð/ (TH)', 'Đặt đầu lưỡi giữa hai hàm răng rồi thổi hơi.', [
    'think',
    'three',
    'mother',
    'I think three is enough',
    'Thank you for this',
    'My mother likes the weather',
    'mouth',
    'thanks',
    'That is the weather',
  ]),
  Lesson('vw', 'Âm /v/ và /w/', '/v/: răng trên chạm môi dưới. /w/: tròn môi, không chạm răng.', [
    'very',
    'van',
    'wine',
    'west',
    'We visit very warm villages',
    'vest',
    'vine',
    'We would visit the van',
  ]),
  Lesson('rl', 'Âm /r/ và /l/', '/r/: cong lưỡi, không chạm vòm. /l/: đầu lưỡi chạm lợi trên.', [
    'right',
    'light',
    'road',
    'load',
    'The red light is right there',
    'rice',
    'lice',
    'Please feel free to leave',
  ]),
  Lesson('ii', 'Nguyên âm /iː/ và /ɪ/', '/iː/ kéo dài, căng môi. /ɪ/ ngắn, thả lỏng.', [
    'sheep',
    'ship',
    'leave',
    'live',
    'Please sit in this seat',
    'feel',
    'fill',
    'Fill the cup',
  ]),
  Lesson('final', 'Phụ âm cuối', 'Người Việt hay nuốt âm cuối. Bật rõ /t/, /d/, /k/, /s/, /z/.', [
    'cats',
    'book',
    'played',
    'dogs',
    'She likes cats and dogs',
    'books',
    'best',
    'I like books',
  ]),
  Lesson('ssh', 'Âm /s/ và /ʃ/', '/s/: răng khép, lưỡi phẳng. /ʃ/: tròn môi, lưỡi lùi về sau.', [
    'see',
    'she',
    'sell',
    'shell',
    'She sells sea shells',
    'sip',
    'ship',
    'She shall sit in the sea',
  ]),
  Lesson('vowels', 'Các nguyên âm dễ nhầm', 'Chú ý độ mở miệng và độ tròn môi: /æ/ rộng, /e/ vừa, /ʌ/ lỏng, /ɔ/ và /oʊ/ tròn môi.', [
    'bat',
    'bet',
    'cup',
    'dog',
    'road',
    'book',
    'two',
    'The red van',
  ]),
  Lesson('daily', 'Câu giao tiếp hằng ngày', 'Luyện ngữ điệu với câu thường dùng.', [
    'How are you today',
    'Nice to meet you',
    'What time is it',
    'I would like a cup of coffee',
    'How are you',
    'Thanks for the coffee',
  ]),
];

/// Điểm tối thiểu của một mục để coi là đã thành thạo.
const masteryScore = 80;

/// Số mục của [l] đạt [masteryScore]. [itemBest] ánh xạ câu mẫu → điểm cao nhất.
int masteredCount(Lesson l, Map<String, int> itemBest) =>
    l.items.where((i) => (itemBest[i] ?? 0) >= masteryScore).length;

/// Chỉ số mục đầu tiên chưa thành thạo để luyện tiếp (0 nếu đã thành thạo hết).
int firstUnmastered(Lesson l, Map<String, int> itemBest) {
  final i = l.items.indexWhere((t) => (itemBest[t] ?? 0) < masteryScore);
  return i < 0 ? 0 : i;
}

Lesson lessonById(String id) => lessons.firstWhere((l) => l.id == id);
