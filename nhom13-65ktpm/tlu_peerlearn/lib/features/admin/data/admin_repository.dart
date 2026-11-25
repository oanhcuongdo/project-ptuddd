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
    final roomsRes = await _client.from('ck_study_rooms').select('id, is_open');
    final sessionsRes =
        await _client.from('ck_tutoring_sessions').select('id, status');

    final rooms = roomsRes as List<dynamic>;
    final sessions = sessionsRes as List<dynamic>;

    return AdminOverviewStats(
      totalMentors: (mentorsRes as List).length,
      totalMentees: (menteesRes as List).length,
      totalRooms: rooms.length,
      activeRooms: rooms.where((r) => r['is_open'] == true).length,
      totalSessions: sessions.length,
      completedSessions:
          sessions.where((s) => s['status'] == 'completed').length,
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
