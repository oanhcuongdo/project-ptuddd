import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/sessions/services/sessions_service.dart';

void main() {
  group('SessionsService Unit Tests (Module 6 SES)', () {
    late SessionsService service;

    setUp(() {
      service = SessionsService(null); // In-memory fallback
    });

    test('validateSessionTimes ensures end time is after start time (SES-01)', () {
      final now = DateTime.now();
      final validEnd = now.add(const Duration(hours: 2));
      final invalidEnd = now.subtract(const Duration(hours: 1));

      expect(SessionsService.validateSessionTimes(now, validEnd), isNull);
      expect(
        SessionsService.validateSessionTimes(now, invalidEnd),
        'Thời gian kết thúc phải diễn ra sau thời gian bắt đầu',
      );
    });

    test('validateEvidenceSize rejects images > 500KB (BR-04, SES-02)', () {
      expect(SessionsService.validateEvidenceSize(100 * 1024), isNull); // 100KB OK
      expect(SessionsService.validateEvidenceSize(500 * 1024), isNull); // 500KB OK
      expect(
        SessionsService.validateEvidenceSize(501 * 1024),
        contains('vượt quá giới hạn 500KB'),
      ); // 501KB FAIL
      expect(
        SessionsService.validateEvidenceSize(0),
        contains('không hợp lệ'),
      );
    });

    test('createSession throws ArgumentError when time range is invalid', () async {
      final now = DateTime.now();
      expect(
        () => service.createSession(
          roomId: 'room1',
          mentorId: 'm1',
          title: 'Buổi học',
          scheduledStart: now,
          scheduledEnd: now.subtract(const Duration(minutes: 30)),
          mode: 'offline',
        ),
        throwsArgumentError,
      );
    });

    test('createSession creates valid session with mock fallback (SES-01)', () async {
      final now = DateTime.now();
      final session = await service.createSession(
        roomId: 'room1',
        mentorId: 'm1',
        title: 'Hướng dẫn chuẩn hóa CSDL',
        scheduledStart: now,
        scheduledEnd: now.add(const Duration(hours: 2)),
        mode: 'online',
        locationOrLink: 'https://meet.google.com/abc-xyz',
        plannedContent: '1NF, 2NF, 3NF',
      );

      expect(session.title, 'Hướng dẫn chuẩn hóa CSDL');
      expect(session.isOnline, isTrue);
      expect(session.isScheduled, isTrue);
    });
  });
}
