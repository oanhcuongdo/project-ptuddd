import '../../../../core/database/database_tables.dart';
import '../../../../core/network/supabase_config.dart';
import '../../../auth_profile/data/models/language_model.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../models/conversation_model.dart';
import '../models/room_join_request.dart';

/// Lớp truy xuất 100% trực tuyến trên Supabase cho danh sách Phòng Chat, Thành viên & Kiểm duyệt.
class ChatRepository {
  ChatRepository({NotificationRepository? notificationRepository})
      : _notifications = notificationRepository ?? NotificationRepository();

  final NotificationRepository _notifications;

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

  Future<Map<String, String>> _fetchProfileNames(Iterable<String> userIds) async {
    final ids = userIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const {};

    final rows = await SupabaseConfig.client
        .from(DatabaseTables.profiles)
        .select('user_id, display_name')
        .inFilter('user_id', ids);

    final map = <String, String>{};
    for (final p in rows) {
      final name = (p['display_name'] as String?)?.trim() ?? '';
      map[p['user_id'].toString()] = name.isNotEmpty ? name : 'Người dùng';
    }
    return map;
  }

  /// Tải tất cả phòng người dùng đã là thành viên chính thức (`status = 'approved'`)
  Future<List<ConversationModel>> fetchMyConversations(String userId) async {
    final client = SupabaseConfig.client;

    final myMemberships = await client
        .from(DatabaseTables.conversationMembers)
        .select('conversation_id, role, status')
        .eq('user_id', userId);

    final approvedMemberships = myMemberships
        .where((row) => (row['status'] as String? ?? 'approved') == 'approved')
        .toList();

    if (approvedMemberships.isEmpty) return const [];

    final roleByConv = <String, String>{};
    for (final row in approvedMemberships) {
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
        .select('conversation_id, user_id, status')
        .inFilter('conversation_id', convIds);

    final approvedCountMap = <String, int>{};
    final pendingCountMap = <String, int>{};
    final partnerByDirectConv = <String, String>{};

    for (final m in allMembers) {
      final cid = m['conversation_id'].toString();
      final uid = m['user_id'].toString();
      final status = m['status'] as String? ?? 'approved';
      if (status == 'pending') {
        pendingCountMap[cid] = (pendingCountMap[cid] ?? 0) + 1;
      } else {
        approvedCountMap[cid] = (approvedCountMap[cid] ?? 0) + 1;
        if (uid != userId) {
          partnerByDirectConv[cid] = uid;
        }
      }
    }

    final creatorIds = convRows.map<String>((r) => r['created_by'].toString());
    final profileNames = await _fetchProfileNames([
      ...creatorIds,
      ...partnerByDirectConv.values,
    ]);

    return convRows.map<ConversationModel>((row) {
      final id = row['id'].toString();
      final type = row['type'] as String? ?? 'group';
      final creatorId = row['created_by'].toString();
      String? resolvedName;
      if (type == 'direct') {
        final partnerId = partnerByDirectConv[id];
        resolvedName = partnerId != null
            ? (profileNames[partnerId] ?? 'Bạn đồng hành')
            : 'Bạn đồng hành';
      }
      return ConversationModel.fromMap(
        row,
        memberCount: approvedCountMap[id] ?? 1,
        pendingCount: pendingCountMap[id] ?? 0,
        isJoined: true,
        membershipStatus: 'approved',
        myRole: roleByConv[id],
        resolvedName: resolvedName,
        managerName: profileNames[creatorId] ?? 'Quản trị phòng',
      );
    }).toList();
  }

  /// Tải danh sách phòng học nhóm công khai kèm trạng thái tham gia / chờ duyệt
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
        .select('conversation_id, user_id, role, status')
        .inFilter('conversation_id', convIds);

    final approvedCountMap = <String, int>{};
    final pendingCountMap = <String, int>{};
    final myRoleMap = <String, String>{};
    final myStatusMap = <String, String>{};

    for (final m in members) {
      final cid = m['conversation_id'].toString();
      final status = m['status'] as String? ?? 'approved';
      if (status == 'pending') {
        pendingCountMap[cid] = (pendingCountMap[cid] ?? 0) + 1;
      } else {
        approvedCountMap[cid] = (approvedCountMap[cid] ?? 0) + 1;
      }
      if (m['user_id'].toString() == userId) {
        myRoleMap[cid] = m['role'] as String? ?? 'member';
        myStatusMap[cid] = status;
      }
    }

    final creatorIds = convRows.map<String>((r) => r['created_by'].toString());
    final profileNames = await _fetchProfileNames(creatorIds);

    return convRows.map<ConversationModel>((row) {
      final id = row['id'].toString();
      final creatorId = row['created_by'].toString();
      final myStatus = myStatusMap[id];
      return ConversationModel.fromMap(
        row,
        memberCount: approvedCountMap[id] ?? 0,
        pendingCount: pendingCountMap[id] ?? 0,
        isJoined: myStatus == 'approved',
        membershipStatus: myStatus,
        myRole: myRoleMap[id],
        managerName: profileNames[creatorId] ?? 'Quản trị phòng',
      );
    }).toList();
  }

  /// Tạo phòng học nhóm mới (hỗ trợ chọn Vào ngay hoặc Cần kiểm duyệt)
  Future<ConversationModel> createGroupRoom({
    required String createdBy,
    required String managerName,
    required String name,
    required String description,
    String? level,
    required String targetLang,
    int? maxMembers,
    bool requireApproval = false,
  }) async {
    final client = SupabaseConfig.client;

    final created = await client
        .from(DatabaseTables.conversations)
        .insert({
          'type': 'group',
          'name': name.trim(),
          'description': description.trim(),
          'level': level,
          'target_lang': targetLang,
          'max_members': maxMembers,
          'require_approval': requireApproval,
          'created_by': createdBy,
        })
        .select()
        .single();

    final roomId = created['id'].toString();
    await client.from(DatabaseTables.conversationMembers).insert({
      'conversation_id': roomId,
      'user_id': createdBy,
      'role': 'owner',
      'status': 'approved',
    });

    return ConversationModel.fromMap(
      created,
      memberCount: 1,
      isJoined: true,
      membershipStatus: 'approved',
      myRole: 'owner',
      managerName: managerName,
    );
  }

  /// Tham gia phòng (vào thẳng nếu mở, hoặc gửi yêu cầu `pending` + bắn thông báo Realtime cho chủ phòng)
  Future<void> joinRoom({
    required String conversationId,
    required String userId,
    bool requireApproval = false,
  }) async {
    await SupabaseConfig.client
        .from(DatabaseTables.conversationMembers)
        .upsert({
          'conversation_id': conversationId,
          'user_id': userId,
          'role': 'member',
          'status': requireApproval ? 'pending' : 'approved',
        }, onConflict: 'conversation_id,user_id');

    if (requireApproval) {
      await _notifyRoomOwnerOfJoinRequest(
        conversationId: conversationId,
        requesterId: userId,
      );
    }
  }

  Future<void> _notifyRoomOwnerOfJoinRequest({
    required String conversationId,
    required String requesterId,
  }) async {
    try {
      final room = await SupabaseConfig.client
          .from(DatabaseTables.conversations)
          .select('name, created_by')
          .eq('id', conversationId)
          .maybeSingle();
      if (room == null) return;

      final ownerId = room['created_by'].toString();
      if (ownerId == requesterId) return;

      final names = await _fetchProfileNames([requesterId]);
      final requesterName = names[requesterId] ?? 'Một thành viên';
      final roomName = (room['name'] as String?)?.trim() ?? 'phòng học';

      await _notifications.createNotification(
        userId: ownerId,
        actorId: requesterId,
        type: 'room_join_request',
        title: 'Yêu cầu tham gia phòng mới',
        body: '$requesterName vừa xin tham gia phòng "$roomName".',
        referenceId: conversationId,
      );
    } catch (_) {
      // Không chặn luồng xin tham gia nếu bảng notifications chưa được tạo
    }
  }

  /// Rời phòng hoặc hủy yêu cầu xin tham gia đang chờ duyệt
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

  /// Lấy danh sách yêu cầu xin vào phòng đang chờ duyệt (dành cho Người quản lý phòng)
  Future<List<RoomJoinRequest>> fetchPendingRequests(
    String conversationId,
  ) async {
    final client = SupabaseConfig.client;
    final rows = await client
        .from(DatabaseTables.conversationMembers)
        .select('user_id, joined_at')
        .eq('conversation_id', conversationId)
        .eq('status', 'pending')
        .order('joined_at', ascending: true);

    if (rows.isEmpty) return const [];

    final userIds = rows.map<String>((r) => r['user_id'].toString()).toList();
    final profiles = await client
        .from(DatabaseTables.profiles)
        .select('user_id, display_name, avatar_url, proficiency_level')
        .inFilter('user_id', userIds);

    final profileMap = <String, Map<String, dynamic>>{};
    for (final p in profiles) {
      profileMap[p['user_id'].toString()] = p;
    }

    return rows.map<RoomJoinRequest>((r) {
      final uid = r['user_id'].toString();
      final p = profileMap[uid];
      final rawName = (p?['display_name'] as String?)?.trim() ?? '';
      return RoomJoinRequest(
        userId: uid,
        displayName: rawName.isNotEmpty ? rawName : 'Người dùng',
        avatarUrl: p?['avatar_url'] as String?,
        proficiencyLevel: p?['proficiency_level'] as String? ?? 'A1',
        requestedAt: r['joined_at'] != null
            ? DateTime.tryParse(r['joined_at'].toString())
            : null,
      );
    }).toList();
  }

  /// Người quản lý phòng duyệt thành viên vào phòng & bắn thông báo Realtime cho người xin
  Future<void> approveJoinRequest({
    required String conversationId,
    required String targetUserId,
  }) async {
    await SupabaseConfig.client
        .from(DatabaseTables.conversationMembers)
        .update({'status': 'approved'})
        .eq('conversation_id', conversationId)
        .eq('user_id', targetUserId);

    await _notifyDecision(
      conversationId: conversationId,
      targetUserId: targetUserId,
      approved: true,
    );
  }

  /// Người quản lý phòng từ chối yêu cầu xin vào phòng & bắn thông báo Realtime
  Future<void> rejectJoinRequest({
    required String conversationId,
    required String targetUserId,
  }) async {
    await leaveRoom(conversationId: conversationId, userId: targetUserId);

    await _notifyDecision(
      conversationId: conversationId,
      targetUserId: targetUserId,
      approved: false,
    );
  }

  Future<void> _notifyDecision({
    required String conversationId,
    required String targetUserId,
    required bool approved,
  }) async {
    try {
      final room = await SupabaseConfig.client
          .from(DatabaseTables.conversations)
          .select('name, created_by')
          .eq('id', conversationId)
          .maybeSingle();
      if (room == null) return;

      final roomName = (room['name'] as String?)?.trim() ?? 'phòng học';
      final ownerId = room['created_by']?.toString();

      // 1. Gửi thông báo Realtime cho người đã xin tham gia
      await _notifications.createNotification(
        userId: targetUserId,
        actorId: ownerId,
        type: approved ? 'room_join_approved' : 'room_join_rejected',
        title: approved
            ? 'Đã được duyệt vào phòng học'
            : 'Yêu cầu tham gia chưa được duyệt',
        body: approved
            ? 'Quản lý phòng đã duyệt bạn vào "$roomName". Vào trò chuyện ngay!'
            : 'Yêu cầu tham gia phòng "$roomName" đã bị từ chối.',
        referenceId: conversationId,
      );

      // 2. Cập nhật lịch sử thông báo cho chính Người quản lý phòng
      if (ownerId != null && ownerId != targetUserId) {
        final names = await _fetchProfileNames([targetUserId]);
        final requesterName = names[targetUserId] ?? 'Một thành viên';

        await _notifications.deleteJoinRequestNotifications(
          ownerId: ownerId,
          requesterId: targetUserId,
          conversationId: conversationId,
        );

        await _notifications.createNotification(
          userId: ownerId,
          actorId: targetUserId,
          type: approved
              ? 'room_join_handled_approved'
              : 'room_join_handled_rejected',
          title: approved ? 'Đã duyệt thành viên' : 'Đã từ chối yêu cầu',
          body: approved
              ? 'Bạn đã duyệt $requesterName vào phòng "$roomName".'
              : 'Bạn đã từ chối $requesterName vào phòng "$roomName".',
          referenceId: conversationId,
          isRead: true,
        );
      }
    } catch (_) {
      // Không chặn thao tác duyệt/từ chối nếu bảng notifications chưa tồn tại
    }
  }
}
