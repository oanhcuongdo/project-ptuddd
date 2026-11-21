import 'package:english_pronunciation_app/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final morning = DateTime(2026, 11, 21, 9, 0);

  test('chưa luyện và chưa tới giờ nhắc → nhắc ngay hôm nay', () {
    expect(nextReminderTime(morning, 20, 0, practicedToday: false), DateTime(2026, 11, 21, 20, 0));
  });

  test('đã luyện hôm nay → dời sang ngày mai', () {
    expect(nextReminderTime(morning, 20, 0, practicedToday: true), DateTime(2026, 11, 22, 20, 0));
  });

  test('đã qua giờ nhắc → ngày mai', () {
    final night = DateTime(2026, 11, 21, 21, 30);
    expect(nextReminderTime(night, 20, 0, practicedToday: false), DateTime(2026, 11, 22, 20, 0));
  });

  test('đúng giờ nhắc (không còn ở tương lai) → ngày mai', () {
    final exact = DateTime(2026, 11, 21, 20, 0);
    expect(nextReminderTime(exact, 20, 0, practicedToday: false), DateTime(2026, 11, 22, 20, 0));
  });

  test('qua ranh giới tháng', () {
    final eom = DateTime(2026, 11, 30, 21, 0);
    expect(nextReminderTime(eom, 20, 0, practicedToday: true), DateTime(2026, 12, 1, 20, 0));
  });
}
