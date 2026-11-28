import 'package:flutter_test/flutter_test.dart';
import 'package:dcsleep/data/models/ai_message_model.dart';

void main() {
  test('AIMessageModel serialization includes isOffline flag', () {
    final msg = AIMessageModel(
      id: 1,
      text: 'Thở 4-7-8',
      isUser: false,
      isOffline: true,
      timestamp: DateTime.parse('2026-11-21T08:00:00'),
    );
    final map = msg.toMap();
    expect(map['is_offline'], 1);
    final fromMap = AIMessageModel.fromMap(map);
    expect(fromMap.isOffline, true);
  });

  test('AIMessageModel defaults isOffline to false', () {
    final msg = AIMessageModel(
      id: 2,
      text: 'Ngủ ngon',
      isUser: false,
      timestamp: DateTime.parse('2026-11-21T08:00:00'),
    );
    expect(msg.isOffline, false);
    final map = msg.toMap();
    expect(map['is_offline'], 0);
  });
}
