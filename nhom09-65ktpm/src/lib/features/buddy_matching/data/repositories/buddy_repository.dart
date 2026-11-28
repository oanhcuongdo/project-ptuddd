import '../../../../core/database/database_tables.dart';
import '../../../../core/network/supabase_config.dart';
import '../../../auth_profile/data/models/profile_model.dart';
import '../models/buddy_model.dart';

/// Reads and updates buddy requests in Supabase.
class BuddyRepository {
  Future<List<ProfileModel>> fetchCandidates(
      ProfileModel currentProfile) async {
    final rows = await SupabaseConfig.client
        .from(DatabaseTables.profiles)
        .select(
          'user_id, display_name, avatar_url, bio, native_lang, target_lang, '
          'proficiency_level, daily_goal_minutes, streak_count, best_streak, '
          'is_online, onboarding_completed',
        )
        .eq('native_lang', currentProfile.targetLang.toLowerCase())
        .eq('target_lang', currentProfile.nativeLang.toLowerCase())
        .eq('onboarding_completed', true)
        .neq('user_id', currentProfile.userId)
        .order('is_online', ascending: false)
        .order('display_name')
        .limit(100);

    return rows.map<ProfileModel>((row) => ProfileModel.fromMap(row)).toList();
  }

  Future<List<BuddyModel>> fetchMatches(String userId) async {
    final rows = await SupabaseConfig.client
        .from(DatabaseTables.buddyMatches)
        .select()
        .or('requester_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false);

    return rows.map<BuddyModel>((row) => BuddyModel.fromMap(row)).toList();
  }

  Future<Map<String, ProfileModel>> fetchProfiles(
    Iterable<String> userIds,
  ) async {
    final ids = userIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const {};

    final rows = await SupabaseConfig.client
        .from(DatabaseTables.profiles)
        .select(
          'user_id, display_name, avatar_url, bio, native_lang, target_lang, '
          'proficiency_level, daily_goal_minutes, streak_count, best_streak, '
          'is_online, onboarding_completed',
        )
        .inFilter('user_id', ids);

    return {
      for (final row in rows)
        row['user_id'].toString(): ProfileModel.fromMap(row),
    };
  }

  Future<BuddyModel> sendRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    if (requesterId == receiverId) {
      throw ArgumentError('Không thể gửi lời mời cho chính mình.');
    }

    final client = SupabaseConfig.client;
    final existingRows =
        await client.from(DatabaseTables.buddyMatches).select().or(
              'and(requester_id.eq.$requesterId,receiver_id.eq.$receiverId),'
              'and(requester_id.eq.$receiverId,receiver_id.eq.$requesterId)',
            );
    final existingMatches =
        existingRows.map<BuddyModel>((row) => BuddyModel.fromMap(row)).toList();

    if (existingMatches.any((match) => match.isBlocked)) {
      throw StateError('Không thể gửi lời mời cho người dùng đã bị chặn.');
    }
    if (existingMatches.any((match) => match.isAccepted)) {
      throw StateError('Hai bạn đã là bạn đồng hành.');
    }
    if (existingMatches.any((match) => match.isPending)) {
      throw StateError('Lời mời giữa hai bạn đang chờ phản hồi.');
    }

    final rejectedRequest = existingMatches.where(
      (match) => match.isRejected && match.requesterId == requesterId,
    );
    if (rejectedRequest.isNotEmpty) {
      final row = await client
          .from(DatabaseTables.buddyMatches)
          .update({'status': BuddyMatchStatus.pending.name, 'matched_at': null})
          .eq('id', rejectedRequest.first.id)
          .select()
          .single();
      return BuddyModel.fromMap(row);
    }

    final row = await client
        .from(DatabaseTables.buddyMatches)
        .insert({
          'requester_id': requesterId,
          'receiver_id': receiverId,
          'status': BuddyMatchStatus.pending.name,
        })
        .select()
        .single();
    return BuddyModel.fromMap(row);
  }

  Future<void> respondToRequest({
    required String matchId,
    required String receiverId,
    required bool accept,
  }) async {
    final values = <String, dynamic>{
      'status': accept
          ? BuddyMatchStatus.accepted.name
          : BuddyMatchStatus.rejected.name,
      'matched_at': accept ? DateTime.now().toUtc().toIso8601String() : null,
    };

    final updated = await SupabaseConfig.client
        .from(DatabaseTables.buddyMatches)
        .update(values)
        .eq('id', matchId)
        .eq('receiver_id', receiverId)
        .eq('status', BuddyMatchStatus.pending.name)
        .select('id')
        .maybeSingle();

    if (updated == null) {
      throw StateError('Lời mời không còn hợp lệ hoặc đã được xử lý.');
    }
  }
}
