import '../../../../core/database/database_tables.dart';
import '../../../../core/network/supabase_config.dart';
import '../../../auth_profile/data/models/language_model.dart';
import '../models/conversation_model.dart';

/// Lớp truy xuất 100% trực tuyến trên Supabase cho danh sách Phòng Chat & Thành viên phòng.
class ChatRepository {
  bool get isReady => SupabaseConfig.isConfigured;

  /// Tải danh mục ngôn ngữ đang mở từ bảng `languages` (Admin cấp phép)
  Future<List<LanguageModel>> fetchAllowedLanguages() async {
    final rows = await SupabaseConfig.client
        .from(DatabaseTables.languages)
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return rows
        .map<LanguageModel>((row) => LanguageModel.fromMap(row))
        .toList();
  }

  /// Tải tất cả phòng người dùng đã tham gia (Chat 1-1 và Nhóm học tập)
  Future<List<ConversationModel>> fetchMyConversations(String userId) async {
    final client = SupabaseConfig.client;

    final myMemberships = await client
        .from(DatabaseTables.conversationMembers)
        .select('conversation_id, role')
        .eq('user_id', userId);

    if (myMemberships.isEmpty) return const [];

    final roleByConv = <String, String>{};
    for (final row in myMemberships) {
      roleByConv[row['conversation_id'].toString()] =
          row['role'] as String? ?? 'member';
    }
    final convIds = roleByConv.keys.toList();

    final convRows = await client
        .from(DatabaseTables.conversations)
        .select()
        .inFilter('id', convIds)
        .order('last_message_at', ascending: false);

    final allMembers = await client
        .from(DatabaseTables.conversationMembers)
        .select('conversation_id, user_id')
        .inFilter('conversation_id', convIds);

    final countMap = <String, int>{};
    final partnerByDirectConv = <String, String>{};
    for (final m in allMembers) {
      final cid = m['conversation_id'].toString();
      final uid = m['user_id'].toString();
      countMap[cid] = (countMap[cid] ?? 0) + 1;
      if (uid != userId) {
        partnerByDirectConv[cid] = uid;
      }
    }

    // Lấy tên hiển thị đối tác cho các phòng Chat 1-1
    final partnerIds = partnerByDirectConv.values.toSet().toList();
    final partnerNames = <String, String>{};
    if (partnerIds.isNotEmpty) {
      final profiles = await client
          .from(DatabaseTables.profiles)
          .select('user_id, display_name')
          .inFilter('user_id', partnerIds);
      for (final p in profiles) {
        partnerNames[p['user_id'].toString()] =
            p['display_name'] as String? ?? 'Buddy';
      }
    }

    return convRows.map<ConversationModel>((row) {
      final id = row['id'].toString();
      final type = row['type'] as String? ?? 'group';
      String? resolvedName;
      if (type == 'direct') {
        final partnerId = partnerByDirectConv[id];
        resolvedName = partnerId != null
            ? (partnerNames[partnerId] ?? 'Bạn đồng hành')
            : 'Bạn đồng hành';
      }
      return ConversationModel.fromMap(
        row,
        memberCount: countMap[id] ?? 1,
        isJoined: true,
        myRole: roleByConv[id],
        resolvedName: resolvedName,
      );
    }).toList();
  }

  /// Tải danh sách phòng học nhóm công khai để người dùng tìm kiếm & tham gia
  Future<List<ConversationModel>> fetchPublicGroupRooms({
    required String userId,
    String? searchQuery,
    String? targetLang,
    String? level,
  }) async {
    final client = SupabaseConfig.client;

    var query = client
        .from(DatabaseTables.conversations)
        .select()
        .eq('type', 'group');

    if (targetLang != null && targetLang.isNotEmpty) {
      query = query.eq('target_lang', targetLang);
    }
    if (level != null && level.isNotEmpty) {
      query = query.eq('level', level);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query = query.ilike('name', '%${searchQuery.trim()}%');
    }

    final convRows = await query.order('created_at', ascending: false);
    if (convRows.isEmpty) return const [];

    final convIds = convRows.map<String>((r) => r['id'].toString()).toList();
    final members = await client
        .from(DatabaseTables.conversationMembers)
        .select('conversation_id, user_id, role')
        .inFilter('conversation_id', convIds);

    final countMap = <String, int>{};
    final myRoleMap = <String, String>{};
    for (final m in members) {
      final cid = m['conversation_id'].toString();
      countMap[cid] = (countMap[cid] ?? 0) + 1;
      if (m['user_id'].toString() == userId) {
        myRoleMap[cid] = m['role'] as String? ?? 'member';
      }
    }

    return convRows.map<ConversationModel>((row) {
      final id = row['id'].toString();
      return ConversationModel.fromMap(
        row,
        memberCount: countMap[id] ?? 0,
        isJoined: myRoleMap.containsKey(id),
        myRole: myRoleMap[id],
      );
    }).toList();
  }

  /// Tham gia một phòng học nhóm trên Supabase
  Future<void> joinRoom({
    required String conversationId,
    required String userId,
  }) async {
    await SupabaseConfig.client
        .from(DatabaseTables.conversationMembers)
        .upsert({
          'conversation_id': conversationId,
          'user_id': userId,
          'role': 'member',
        }, onConflict: 'conversation_id,user_id');
  }

  /// Rời khỏi một phòng học nhóm trên Supabase
  Future<void> leaveRoom({
    required String conversationId,
    required String userId,
  }) async {
    await SupabaseConfig.client
        .from(DatabaseTables.conversationMembers)
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }
}
