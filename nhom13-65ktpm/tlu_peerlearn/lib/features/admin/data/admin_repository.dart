import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../domain/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

final adminOverviewStatsProvider =
    FutureProvider<AdminOverviewStats>((ref) async {
  return ref.watch(adminRepositoryProvider).getOverviewStats();
});

final adminRoomsProvider = FutureProvider<List<AdminRoomSummary>>((ref) async {
  return ref.watch(adminRepositoryProvider).getRooms();
});

final adminSessionLogsProvider =
    FutureProvider<List<AdminSessionLog>>((ref) async {
  return ref.watch(adminRepositoryProvider).getSessionLogs();
});

class AdminRepository {
  final SupabaseClient _client;

  AdminRepository(this._client);

  Future<AdminOverviewStats> getOverviewStats() async {
    final mentorsRes = await _client
        .from('ck_program_registrations')
        .select('id')
        .eq('role', 'mentor');
    final menteesRes = await _client
        .from('ck_program_registrations')
        .select('id')
        .eq('role', 'mentee');
    final roomsRes = await _client.from('ck_study_rooms').select('id');
    final sessionsRes = await _client.from('ck_tutoring_sessions').select('id');
    final setsRes = await _client.from('ck_generated_sets').select('id');
    final attemptsRes = await _client.from('ck_quiz_attempts').select('id');

    return AdminOverviewStats(
      totalMentors: (mentorsRes as List).length,
      totalMentees: (menteesRes as List).length,
      totalRooms: (roomsRes as List).length,
      totalSessions: (sessionsRes as List).length,
      totalGeneratedSets: (setsRes as List).length,
      totalQuizAttempts: (attemptsRes as List).length,
    );
  }

  Future<List<AdminRoomSummary>> getRooms() async {
    final data = await _client
        .from('ck_study_rooms')
        .select('id, name, room_code, is_open, ck_courses(name), ck_profiles(full_name)')
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => AdminRoomSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminSessionLog>> getSessionLogs() async {
    final data = await _client
        .from('ck_tutoring_sessions')
        .select(
          'id, title, scheduled_start, guided_content, status, '
          'ck_study_rooms(name), ck_profiles(full_name), '
          'ck_session_attendances(mentor_marked_status, mentee_confirmed, ck_profiles(full_name)), '
          'ck_session_evidences(image_url)',
        )
        .order('scheduled_start', ascending: false);

    return (data as List<dynamic>)
        .map((e) => AdminSessionLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
