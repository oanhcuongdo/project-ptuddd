import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tutoring_session.dart';

final sessionsServiceProvider = Provider<SessionsService>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    client = null;
  }
  return SessionsService(client);
});

final roomSessionsProvider =
    FutureProvider.family<List<TutoringSession>, String>((ref, roomId) async {
  final service = ref.watch(sessionsServiceProvider);
  return service.fetchRoomSessions(roomId);
});

class SessionsService {
  final SupabaseClient? _client;

  SessionsService([this._client]);

  SupabaseClient? get client => _client;

  static const String sessionsTable = 'ck_tutoring_sessions';
  static const String attendancesTable = 'ck_session_attendances';
  static const String evidencesTable = 'ck_session_evidences';
  static const String roomMembersTable = 'ck_room_members';
  static const String evidenceBucket = 'session-evidences';

  static const int maxEvidenceSize = 500 * 1024; // 500KB (BR-04, BUSINESS_RULES)
  static const List<String> allowedEvidenceExtensions = ['.jpg', '.jpeg', '.png'];

  /// Validates evidence image format (only JPG, JPEG, PNG)
  static String? validateEvidenceFormat(String fileName) {
    final lower = fileName.toLowerCase();
    if (!allowedEvidenceExtensions.any((ext) => lower.endsWith(ext))) {
      return 'Chỉ chấp nhận ảnh định dạng JPG, JPEG hoặc PNG.';
    }
    return null;
  }

  /// Validates evidence image size (must be <= 500KB)
  static String? validateEvidenceSize(int sizeInBytes) {
    if (sizeInBytes <= 0) return 'Tệp hình ảnh không hợp lệ (0 bytes)';
    if (sizeInBytes > maxEvidenceSize) {
      return 'Dung lượng ảnh minh chứng vượt quá giới hạn 500KB. Vui lòng nén ảnh trước khi tải lên.';
    }
    return null;
  }

  /// Validates session time range
  static String? validateSessionTimes(DateTime start, DateTime end) {
    if (!end.isAfter(start)) {
      return 'Thời gian kết thúc phải diễn ra sau thời gian bắt đầu';
    }
    return null;
  }

  /// Fetches all sessions for a study room (SES-01)
  Future<List<TutoringSession>> fetchRoomSessions(String roomId) async {
    if (_client == null) return [];

    try {
      final res = await _client
          .from(sessionsTable)
          .select('*, ck_profiles(full_name)')
          .eq('room_id', roomId)
          .order('scheduled_start', ascending: false);

      return (res as List<dynamic>)
          .map((row) => TutoringSession.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Schedules a new tutoring session (SES-01)
  Future<TutoringSession> createSession({
    required String roomId,
    required String mentorId,
    required String title,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required String mode, // 'offline' | 'online'
    String? locationOrLink,
    String? plannedContent,
  }) async {
    final timeError = validateSessionTimes(scheduledStart, scheduledEnd);
    if (timeError != null) throw ArgumentError(timeError);

    if (_client == null) {
      return TutoringSession(
        id: 'mock-session-${DateTime.now().millisecondsSinceEpoch}',
        roomId: roomId,
        mentorId: mentorId,
        title: title,
        scheduledStart: scheduledStart,
        scheduledEnd: scheduledEnd,
        mode: mode,
        locationOrLink: locationOrLink,
        plannedContent: plannedContent,
        createdAt: DateTime.now(),
      );
    }

    final res = await _client
        .from(sessionsTable)
        .insert({
          'room_id': roomId,
          'mentor_id': mentorId,
          'title': title,
          'scheduled_start': scheduledStart.toIso8601String(),
          'scheduled_end': scheduledEnd.toIso8601String(),
          'mode': mode,
          'location_or_link': locationOrLink,
          'planned_content': plannedContent,
          'status': 'scheduled',
        })
        .select()
        .single();

    final session = TutoringSession.fromJson(res);

    // Automatically create attendance placeholders for all mentees in the room
    try {
      final membersRes = await _client
          .from(roomMembersTable)
          .select('user_id')
          .eq('room_id', roomId)
          .eq('role', 'mentee');

      final members = membersRes as List<dynamic>;
      if (members.isNotEmpty) {
        final rows = members.map((m) => {
              'session_id': session.id,
              'mentee_id': m['user_id'],
              'mentor_marked_status': 'absent',
              'mentee_confirmed': false,
            }).toList();
        await _client.from(attendancesTable).insert(rows);
      }
    } catch (_) {
      // Ignore if room members table isn't populated in dev
    }

    return session;
  }

  /// Updates an existing scheduled session
  Future<void> updateSession({
    required String sessionId,
    required String title,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required String mode,
    String? locationOrLink,
    String? plannedContent,
  }) async {
    final timeError = validateSessionTimes(scheduledStart, scheduledEnd);
    if (timeError != null) throw ArgumentError(timeError);
    if (_client == null) return;

    await _client.from(sessionsTable).update({
      'title': title,
      'scheduled_start': scheduledStart.toIso8601String(),
      'scheduled_end': scheduledEnd.toIso8601String(),
      'mode': mode,
      'location_or_link': locationOrLink,
      'planned_content': plannedContent,
    }).eq('id', sessionId);
  }

  /// Deletes a scheduled session
  Future<void> deleteSession(String sessionId) async {
    if (_client == null) return;
    await _client.from(sessionsTable).delete().eq('id', sessionId);
  }

  /// Fetches attendances for a session
  Future<List<SessionAttendance>> fetchAttendances(String sessionId) async {
    if (_client == null) return [];

    try {
      final res = await _client
          .from(attendancesTable)
          .select('*, ck_profiles(full_name)')
          .eq('session_id', sessionId);

      return (res as List<dynamic>)
          .map((row) => SessionAttendance.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches evidences for a session
  Future<List<SessionEvidence>> fetchEvidences(String sessionId) async {
    if (_client == null) return [];

    try {
      final res = await _client
          .from(evidencesTable)
          .select()
          .eq('session_id', sessionId)
          .order('uploaded_at', ascending: false);

      return (res as List<dynamic>)
          .map((row) => SessionEvidence.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Completes session report and records mentor attendance (SES-02, BR-09)
  Future<void> completeSessionReport({
    required String sessionId,
    required int actualDurationMinutes,
    required String guidedContent,
    String? outcomes,
    String? issues,
    required Map<String, String> attendanceStatuses, // menteeId -> 'present' | 'absent'
  }) async {
    if (_client == null) return;

    // 1. Update session status
    await _client.from(sessionsTable).update({
      'actual_duration_minutes': actualDurationMinutes,
      'guided_content': guidedContent,
      'outcomes': outcomes,
      'issues': issues,
      'status': 'completed',
    }).eq('id', sessionId);

    // 2. Update mentor-marked attendance
    for (final entry in attendanceStatuses.entries) {
      await _client
          .from(attendancesTable)
          .update({'mentor_marked_status': entry.value})
          .eq('session_id', sessionId)
          .eq('mentee_id', entry.key);
    }
  }

  /// Mentee confirms attendance independently (SES-03, BR-09, BR-10)
  Future<void> confirmAttendanceByMentee({
    required String sessionId,
    required String menteeId,
  }) async {
    if (_client == null) return;

    await _client.from(attendancesTable).update({
      'mentee_confirmed': true,
      'mentee_confirmed_at': DateTime.now().toIso8601String(),
    }).eq('session_id', sessionId).eq('mentee_id', menteeId);
  }

  /// Uploads session evidence image (SES-02, max 1 image, JPG/JPEG/PNG, <= 500KB)
  Future<SessionEvidence> uploadEvidence({
    required String sessionId,
    required Uint8List imageBytes,
    required String fileName,
    String? caption,
  }) async {
    final formatError = validateEvidenceFormat(fileName);
    if (formatError != null) throw ArgumentError(formatError);
    final sizeError = validateEvidenceSize(imageBytes.length);
    if (sizeError != null) throw ArgumentError(sizeError);

    if (_client != null) {
      // Keep only 1 evidence image per session
      await _client.from(evidencesTable).delete().eq('session_id', sessionId);
    }

    if (_client == null) {
      return SessionEvidence(
        id: 'mock-evidence-${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        imageUrl: 'https://example.com/mock-evidence.jpg',
        caption: caption,
        uploadedAt: DateTime.now(),
      );
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$sessionId/${timestamp}_$fileName';

    await _client.storage.from(evidenceBucket).uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    final publicUrl = _client.storage.from(evidenceBucket).getPublicUrl(storagePath);

    final record = await _client
        .from(evidencesTable)
        .insert({
          'session_id': sessionId,
          'image_url': publicUrl,
          'caption': caption,
        })
        .select()
        .single();

    return SessionEvidence.fromJson(record);
  }
}
