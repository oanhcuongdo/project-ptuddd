import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/database_tables.dart';
import '../../../../core/network/supabase_config.dart';
import '../../../auth_profile/data/models/language_model.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/online_member_model.dart';
import '../models/room_join_request.dart';
import '../models/room_member_model.dart';

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

  /// Tải danh sách thành viên đang trực tuyến thật từ bảng `profiles` (`is_online = true`)
  Future<List<OnlineMemberModel>> fetchOnlineMembers({
    required String excludeUserId,
    int limit = 6,
  }) async {
    try {
      final rows = await SupabaseConfig.client
          .from(DatabaseTables.profiles)
          .select('user_id, display_name, avatar_url, target_lang, proficiency_level')
          .eq('is_online', true)
          .neq('user_id', excludeUserId)
          .limit(limit);

      return rows
          .map<OnlineMemberModel>((r) => OnlineMemberModel.fromMap(r))
          .toList();
    } catch (_) {
      return const [];
    }
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

    List<dynamic> myMemberships;
    try {
      myMemberships = await client
          .from(DatabaseTables.conversationMembers)
          .select(
            'conversation_id, role, status, streak_count, best_streak, last_chat_date',
          )
          .eq('user_id', userId);
    } catch (_) {
      myMemberships = await client
          .from(DatabaseTables.conversationMembers)
          .select('conversation_id, role, status')
          .eq('user_id', userId);
    }

    final approvedMemberships = myMemberships
        .where((row) => (row['status'] as String? ?? 'approved') == 'approved')
        .toList();

    if (approvedMemberships.isEmpty) return const [];

    final roleByConv = <String, String>{};
    final streakByConv = <String, ({int count, int best, DateTime? lastDate})>{};
    for (final row in approvedMemberships) {
      final cid = row['conversation_id'].toString();
      roleByConv[cid] = row['role'] as String? ?? 'member';
      streakByConv[cid] = (
        count: (row['streak_count'] as num?)?.toInt() ?? 0,
        best: (row['best_streak'] as num?)?.toInt() ?? 0,
        lastDate: ConversationModel.parseDateOnly(row['last_chat_date']),
      );
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
      final streakInfo = streakByConv[id];
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
        roomStreakCount: streakInfo?.count ?? 0,
        bestStreak: streakInfo?.best ?? 0,
        lastChatDate: streakInfo?.lastDate,
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
    List<dynamic> members;
    try {
      members = await client
          .from(DatabaseTables.conversationMembers)
          .select(
            'conversation_id, user_id, role, status, streak_count, best_streak, last_chat_date',
          )
          .inFilter('conversation_id', convIds);
    } catch (_) {
      members = await client
          .from(DatabaseTables.conversationMembers)
          .select('conversation_id, user_id, role, status')
          .inFilter('conversation_id', convIds);
    }

    final approvedCountMap = <String, int>{};
    final pendingCountMap = <String, int>{};
    final myRoleMap = <String, String>{};
    final myStatusMap = <String, String>{};
    final myStreakMap = <String, ({int count, int best, DateTime? lastDate})>{};

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
        myStreakMap[cid] = (
          count: (m['streak_count'] as num?)?.toInt() ?? 0,
          best: (m['best_streak'] as num?)?.toInt() ?? 0,
          lastDate: ConversationModel.parseDateOnly(m['last_chat_date']),
        );
      }
    }

    final creatorIds = convRows.map<String>((r) => r['created_by'].toString());
    final profileNames = await _fetchProfileNames(creatorIds);

    return convRows.map<ConversationModel>((row) {
      final id = row['id'].toString();
      final creatorId = row['created_by'].toString();
      final myStatus = myStatusMap[id];
      final streakInfo = myStreakMap[id];
      return ConversationModel.fromMap(
        row,
        memberCount: approvedCountMap[id] ?? 0,
        pendingCount: pendingCountMap[id] ?? 0,
        isJoined: myStatus == 'approved',
        membershipStatus: myStatus,
        myRole: myRoleMap[id],
        managerName: profileNames[creatorId] ?? 'Quản trị phòng',
        roomStreakCount: streakInfo?.count ?? 0,
        bestStreak: streakInfo?.best ?? 0,
        lastChatDate: streakInfo?.lastDate,
      );
    }).toList();
  }

  /// Tạo phòng học nhóm mới (hỗ trợ Ảnh bìa, Định hướng kỹ năng, Vào ngay / Cần kiểm duyệt)
  Future<ConversationModel> createGroupRoom({
    required String createdBy,
    required String managerName,
    required String name,
    required String description,
    String? level,
    required String targetLang,
    int? maxMembers,
    bool requireApproval = false,
    String? coverUrl,
    String? roomFocus,
  }) async {
    final client = SupabaseConfig.client;

    final basePayload = <String, dynamic>{
      'type': 'group',
      'name': name.trim(),
      'description': description.trim(),
      'level': level,
      'target_lang': targetLang,
      'max_members': maxMembers,
      'require_approval': requireApproval,
      'created_by': createdBy,
    };

    final fullPayload = <String, dynamic>{
      ...basePayload,
      if (coverUrl != null && coverUrl.trim().isNotEmpty)
        'cover_url': coverUrl.trim(),
      if (roomFocus != null && roomFocus.trim().isNotEmpty)
        'room_focus': roomFocus.trim(),
    };

    Map<String, dynamic> created;
    try {
      created = await client
          .from(DatabaseTables.conversations)
          .insert(fullPayload)
          .select()
          .single();
    } catch (_) {
      created = await client
          .from(DatabaseTables.conversations)
          .insert(basePayload)
          .select()
          .single();
    }

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
      final names = await _fetchProfileNames([requesterId]);
      final requesterName = names[requesterId] ?? 'Một thành viên';
      final roomName = (room['name'] as String?)?.trim() ?? 'phòng học';

      // Gửi thông báo cho cả Chủ phòng và các Phó phòng (Trợ giảng)
      final managerRows = await SupabaseConfig.client
          .from(DatabaseTables.conversationMembers)
          .select('user_id')
          .eq('conversation_id', conversationId)
          .inFilter('role', ['owner', 'co_owner']);

      final recipientIds = <String>{
        ownerId,
        ...managerRows.map<String>((r) => r['user_id'].toString()),
      }..remove(requesterId);

      for (final managerId in recipientIds) {
        await _notifications.createNotification(
          userId: managerId,
          actorId: requesterId,
          type: 'room_join_request',
          title: 'Yêu cầu tham gia phòng mới',
          body: '$requesterName vừa xin tham gia phòng "$roomName".',
          referenceId: conversationId,
        );
      }
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

  // ==================== TIN NHẮN REALTIME (BẢNG MESSAGES) ====================

  /// Tải lịch sử tin nhắn mới nhất của một phòng chat từ bảng `messages`
  Future<List<MessageModel>> fetchMessages(
    String conversationId, {
    int limit = 100,
  }) async {
    final client = SupabaseConfig.client;
    final rows = await client
        .from(DatabaseTables.messages)
        .select('id, conversation_id, sender_id, content, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(limit);

    if (rows.isEmpty) return const [];

    final senderIds =
        rows.map<String>((r) => r['sender_id'].toString()).toSet().toList();
    final senderProfiles = await _fetchSenderProfiles(senderIds);

    return rows.reversed.map<MessageModel>((r) {
      final sid = r['sender_id'].toString();
      final info = senderProfiles[sid];
      return MessageModel.fromMap(
        r,
        senderName: info?.name,
        senderAvatarUrl: info?.avatarUrl,
      );
    }).toList();
  }

  /// Gửi tin nhắn mới: lưu thẳng vào bảng `messages` trên Supabase Cloud
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    required String content,
  }) async {
    final inserted = await SupabaseConfig.client
        .from(DatabaseTables.messages)
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'content': content.trim(),
        })
        .select('id, conversation_id, sender_id, content, created_at')
        .single();

    return MessageModel.fromMap(
      inserted,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
    );
  }

  /// Tra cứu tên & avatar người gửi cho tin nhắn mới nhận qua Realtime WebSocket
  Future<({String name, String? avatarUrl})> fetchSenderProfile(
    String userId,
  ) async {
    final map = await _fetchSenderProfiles([userId]);
    return map[userId] ?? (name: 'Thành viên', avatarUrl: null);
  }

  Future<Map<String, ({String name, String? avatarUrl})>> _fetchSenderProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return const {};
    final rows = await SupabaseConfig.client
        .from(DatabaseTables.profiles)
        .select('user_id, display_name, avatar_url')
        .inFilter('user_id', userIds);

    final result = <String, ({String name, String? avatarUrl})>{};
    for (final row in rows) {
      final uid = row['user_id'].toString();
      final rawName = (row['display_name'] as String?)?.trim() ?? '';
      result[uid] = (
        name: rawName.isNotEmpty ? rawName : 'Thành viên',
        avatarUrl: row['avatar_url'] as String?,
      );
    }
    return result;
  }

  /// Mở kênh WebSocket Supabase Realtime lắng nghe tin nhắn mới trong phòng
  RealtimeChannel? subscribeToRoomMessages({
    required String conversationId,
    required void Function(MessageModel message) onNewMessage,
  }) {
    if (!isReady) return null;

    final channel =
        SupabaseConfig.client.channel('room_messages:$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: DatabaseTables.messages,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            if (payload.newRecord.isEmpty) return;
            onNewMessage(MessageModel.fromMap(payload.newRecord));
          },
        )
        .subscribe();

    return channel;
  }

  Future<void> unsubscribeChannel(RealtimeChannel channel) async {
    if (!isReady) return;
    await SupabaseConfig.client.removeChannel(channel);
  }

  /// Cập nhật chuỗi lửa riêng của người dùng trong 1 phòng chat (kiểu TikTok):
  /// - Ban đầu = 0; nhắn 1 tin hôm nay -> +1
  /// - Đã nhắn hôm nay -> giữ nguyên (không +1 lặp lại trong ngày)
  /// - Quên từ 1 ngày trọn vẹn trở lên -> mất chuỗi, bắt đầu lại từ 1
  Future<({int streakCount, int bestStreak, DateTime lastChatDate, bool incrementedToday})?>
      recordRoomChatStreak({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final row = await client
          .from(DatabaseTables.conversationMembers)
          .select('streak_count, best_streak, last_chat_date')
          .eq('conversation_id', conversationId)
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) return null;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayKey = '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';

      final currentStreak = (row['streak_count'] as num?)?.toInt() ?? 0;
      final currentBest = (row['best_streak'] as num?)?.toInt() ?? 0;
      final lastDate = ConversationModel.parseDateOnly(row['last_chat_date']);

      int nextStreak;
      bool incrementedToday;

      if (lastDate == null) {
        nextStreak = 1;
        incrementedToday = true;
      } else {
        final diff = today.difference(lastDate).inDays;
        if (diff <= 0) {
          // Đã thắp lửa trong phòng hôm nay rồi
          nextStreak = currentStreak > 0 ? currentStreak : 1;
          incrementedToday = false;
        } else if (diff == 1) {
          // Nhắn nối tiếp ngày hôm qua -> +1 chuỗi!
          nextStreak = currentStreak + 1;
          incrementedToday = true;
        } else {
          // Quên ít nhất 1 ngày trọn vẹn -> mất chuỗi, bắt đầu lại từ 1
          nextStreak = 1;
          incrementedToday = true;
        }
      }

      final nextBest = nextStreak > currentBest ? nextStreak : currentBest;

      if (incrementedToday || currentStreak == 0) {
        await client
            .from(DatabaseTables.conversationMembers)
            .update({
              'streak_count': nextStreak,
              'best_streak': nextBest,
              'last_chat_date': todayKey,
            })
            .eq('conversation_id', conversationId)
            .eq('user_id', userId);
      }

      return (
        streakCount: nextStreak,
        bestStreak: nextBest,
        lastChatDate: today,
        incrementedToday: incrementedToday,
      );
    } catch (_) {
      // Không chặn luồng gửi tin nhắn nếu migration 012 chưa được chạy
      return null;
    }
  }

  // ==================== THÀNH VIÊN & PHÂN QUYỀN PHÓ PHÒNG ====================

  /// Lấy danh sách tất cả thành viên chính thức trong phòng (Chủ phòng -> Phó phòng -> Thành viên)
  Future<List<RoomMemberModel>> fetchRoomMembers(String conversationId) async {
    final client = SupabaseConfig.client;

    List<dynamic> rows;
    try {
      rows = await client
          .from(DatabaseTables.conversationMembers)
          .select(
            'user_id, role, status, streak_count, last_chat_date, joined_at',
          )
          .eq('conversation_id', conversationId)
          .order('joined_at', ascending: true);
    } catch (_) {
      rows = await client
          .from(DatabaseTables.conversationMembers)
          .select('user_id, role, status, joined_at')
          .eq('conversation_id', conversationId)
          .order('joined_at', ascending: true);
    }

    final approved = rows
        .where((r) => (r['status'] as String? ?? 'approved') == 'approved')
        .toList();
    if (approved.isEmpty) return const [];

    final userIds =
        approved.map<String>((r) => r['user_id'].toString()).toList();
    final profiles = await client
        .from(DatabaseTables.profiles)
        .select('user_id, display_name, avatar_url, proficiency_level')
        .inFilter('user_id', userIds);

    final profileMap = <String, Map<String, dynamic>>{};
    for (final p in profiles) {
      profileMap[p['user_id'].toString()] = p;
    }

    final members = approved
        .map<RoomMemberModel>(
          (r) => RoomMemberModel.fromRow(r, profileMap[r['user_id'].toString()]),
        )
        .toList();

    members.sort((a, b) {
      final roleCmp = a.roleSortOrder.compareTo(b.roleSortOrder);
      if (roleCmp != 0) return roleCmp;
      return b.effectiveStreak.compareTo(a.effectiveStreak);
    });
    return members;
  }

  /// Chủ phòng bổ nhiệm / gỡ quyền Phó phòng (Trợ giảng) & gửi thông báo Realtime
  Future<void> updateMemberRole({
    required String conversationId,
    required String targetUserId,
    required String newRole,
    required String actorId,
    required String roomName,
  }) async {
    await SupabaseConfig.client
        .from(DatabaseTables.conversationMembers)
        .update({'role': newRole})
        .eq('conversation_id', conversationId)
        .eq('user_id', targetUserId);

    try {
      final isPromoted = newRole == 'co_owner';
      await _notifications.createNotification(
        userId: targetUserId,
        actorId: actorId,
        type: isPromoted ? 'room_join_approved' : 'system',
        title: isPromoted
            ? 'Bạn được bổ nhiệm làm Trợ giảng'
            : 'Cập nhật vai trò phòng học',
        body: isPromoted
            ? 'Chủ phòng đã phân bạn làm Trợ giảng tại "$roomName". Bạn có thể hỗ trợ duyệt thành viên và cập nhật nội quy!'
            : 'Vai trò của bạn tại phòng "$roomName" đã chuyển về Thành viên.',
        referenceId: conversationId,
      );
    } catch (_) {}
  }

  /// Chủ phòng hoặc Phó phòng cập nhật mô tả / nội quy phòng học
  Future<void> updateRoomDescription({
    required String conversationId,
    required String description,
  }) async {
    await SupabaseConfig.client
        .from(DatabaseTables.conversations)
        .update({'description': description.trim()})
        .eq('id', conversationId);
  }
}
