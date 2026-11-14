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
  ]),
  Lesson('vw', 'Âm /v/ và /w/', '/v/: răng trên chạm môi dưới. /w/: tròn môi, không chạm răng.', [
    'very',
    'van',
    'wine',
    'west',
    'We visit very warm villages',
  ]),
  Lesson('rl', 'Âm /r/ và /l/', '/r/: cong lưỡi, không chạm vòm. /l/: đầu lưỡi chạm lợi trên.', [
    'right',
    'light',
    'road',
    'load',
    'The red light is right there',
  ]),
  Lesson('ii', 'Nguyên âm /iː/ và /ɪ/', '/iː/ kéo dài, căng môi. /ɪ/ ngắn, thả lỏng.', [
    'sheep',
    'ship',
    'leave',
    'live',
    'Please sit in this seat',
  ]),
  Lesson('final', 'Phụ âm cuối', 'Người Việt hay nuốt âm cuối. Bật rõ /t/, /d/, /k/, /s/, /z/.', [
    'cats',
    'book',
    'played',
    'dogs',
    'She likes cats and dogs',
  ]),
  Lesson('ssh', 'Âm /s/ và /ʃ/', '/s/: răng khép, lưỡi phẳng. /ʃ/: tròn môi, lưỡi lùi về sau.', [
    'see',
    'she',
    'sell',
    'shell',
    'She sells sea shells',
  ]),
  Lesson('daily', 'Câu giao tiếp hằng ngày', 'Luyện ngữ điệu với câu thường dùng.', [
    'How are you today',
    'Nice to meet you',
    'What time is it',
    'I would like a cup of coffee',
  ]),
];

Lesson lessonById(String id) => lessons.firstWhere((l) => l.id == id);
