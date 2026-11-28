import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../notifications/services/notification_service.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../auth_profile/domain/program_registration.dart';
import '../domain/compatibility_match.dart';
import '../domain/room_invitation.dart';
import '../domain/room_member.dart';
import '../domain/study_room.dart';
import '../utils/compatibility_scoring.dart';

final roomMatchingRepositoryProvider = Provider<RoomMatchingRepository>(
  (ref) => RoomMatchingRepository(ref.watch(supabaseClientProvider)),
);

final myRoomsProvider = FutureProvider.family<List<StudyRoom>, String>((
  ref,
  userId,
) {
  return ref.watch(roomMatchingRepositoryProvider).getMyRooms(userId);
});

final roomMembersProvider = FutureProvider.family<List<RoomMember>, String>((
  ref,
  roomId,
) {
  return ref.watch(roomMatchingRepositoryProvider).getRoomMembers(roomId);
});

final studyRoomProvider = FutureProvider.family<StudyRoom, String>((
  ref,
  roomId,
) {
  return ref.watch(roomMatchingRepositoryProvider).getRoom(roomId);
});

final myInvitationsProvider =
    FutureProvider.family<List<RoomInvitation>, String>((ref, userId) {
      return ref.watch(roomMatchingRepositoryProvider).getMyInvitations(userId);
    });

class RoomMatchingRepository {
  static const int _roomCodeLength = 6;
  static const String _roomCodeCharacters =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final RegExp _roomCodePattern =
      RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$');

  final SupabaseClient _client;
  final Random _random;

  RoomMatchingRepository(this._client) : _random = Random.secure();

  Future<List<CompatibilityMatch>> getMatches({
    required ProgramRegistration current,
  }) async {
    if (current.role != 'mentor' && current.role != 'mentee') {
      throw ArgumentError.value(current.role, 'current.role', 'Vai trò không hợp lệ');
    }
    final oppositeRole = current.role == 'mentor' ? 'mentee' : 'mentor';
    final rows = await _client
        .from('ck_program_registrations')
        .select('*, ck_profiles(full_name)')
        .eq('course_id', current.courseId)
        .eq('role', oppositeRole)
        .neq('user_id', current.userId);

    final mentorIds = (rows as List<dynamic>)
        .map((row) => row as Map<String, dynamic>)
        .map(
          (row) => current.role == 'mentor'
              ? current.userId
              : row['user_id'] as String,
        )
        .toSet()
        .toList();
    final menteeCounts = await _getRoomMenteeCounts(
      mentorIds: mentorIds,
      courseId: current.courseId,
    );
    final matches = <CompatibilityMatch>[];
    for (final row in rows) {
      final json = row;
      final registration = ProgramRegistration.fromJson(json);
      final profile = json['ck_profiles'] as Map<String, dynamic>?;
      final mentor = current.role == 'mentor' ? current : registration;
      final mentorId = mentor.userId;
      final timeScore = CompatibilityScoring.timeFit(
        current.availableSlots,
        registration.availableSlots,
      );
      final mentee = current.role == 'mentee' ? current : registration;
      final academicScore = CompatibilityScoring.academicFit(
        mentorGrade: mentor.courseGrade,
        mentorStrength: mentor.strengthsOrNeeds,
        menteeNeed: mentee.strengthsOrNeeds,
      );
      final capacityScore = CompatibilityScoring.capacityFit(
        maxMentees: mentor.maxMentees,
        currentMentees: menteeCounts[mentorId] ?? 0,
      );
      matches.add(
        CompatibilityMatch(
          userId: registration.userId,
          fullName: profile?['full_name'] as String? ?? 'Sinh viên',
          role: registration.role,
          courseId: registration.courseId,
          score: CompatibilityScoring.calculate(
            timeScore: timeScore,
            academicScore: academicScore,
            capacityScore: capacityScore,
          ),
          timeScore: timeScore,
          academicScore: academicScore,
          capacityScore: capacityScore,
          availableSlots: registration.availableSlots,
          courseGrade: registration.courseGrade,
        ),
      );
    }
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }

  Future<Map<String, int>> _getRoomMenteeCounts({
    required List<String> mentorIds,
    required String courseId,
  }) async {
    if (mentorIds.isEmpty) return {};
    final rooms = await _client
        .from('ck_study_rooms')
        .select('id, mentor_id')
        .inFilter('mentor_id', mentorIds)
        .eq('course_id', courseId)
        .eq('is_open', true);
    final roomMentors = <String, String>{};
    for (final row in rooms as List<dynamic>) {
      final room = row as Map<String, dynamic>;
      roomMentors[room['id'] as String] = room['mentor_id'] as String;
    }
    if (roomMentors.isEmpty) return {};
    final members = await _client
        .from('ck_room_members')
        .select('room_id')
        .inFilter('room_id', roomMentors.keys.toList())
        .eq('role', 'mentee');
    final counts = <String, int>{};
    for (final row in members as List<dynamic>) {
      final roomId = (row as Map<String, dynamic>)['room_id'] as String;
      final mentorId = roomMentors[roomId];
      if (mentorId != null) {
        counts.update(mentorId, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    return counts;
  }

  Future<StudyRoom> createRoom({
    required String courseId,
    required String mentorId,
    required String name,
    String? description,
  }) async {
    final trimmedName = name.trim();
    if (courseId.trim().isEmpty || mentorId.trim().isEmpty) {
      throw ArgumentError('Học phần và Mentor không được để trống');
    }
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Tên phòng không được để trống');
    }

    final registration = await _client
        .from('ck_program_registrations')
        .select('role')
        .eq('user_id', mentorId)
        .eq('course_id', courseId)
        .maybeSingle();
    if (registration == null || registration['role'] != 'mentor') {
      throw StateError('Chỉ Mentor đã đăng ký học phần mới được tạo phòng');
    }

    for (var attempt = 0; attempt < 10; attempt++) {
      final code = _generateRoomCode();
      if (!await isRoomCodeAvailable(code)) continue;
      Map<String, dynamic> response;
      try {
        response = await _client
            .from('ck_study_rooms')
            .insert({
              'course_id': courseId,
              'mentor_id': mentorId,
              'name': trimmedName,
              'description': _nullableTrim(description),
              'room_code': code,
            })
            .select()
            .single();
      } on PostgrestException catch (error) {
        if (error.code != '23505' || attempt == 9) rethrow;
        continue;
      }
      final room = StudyRoom.fromJson(response);
      await _client.from('ck_room_members').upsert({
        'room_id': room.id,
        'user_id': mentorId,
        'role': 'mentor',
      }, onConflict: 'room_id,user_id');
      return room;
    }
    throw StateError('Không thể tạo mã phòng duy nhất');
  }

  Future<bool> isRoomCodeAvailable(String roomCode) async {
    final normalizedCode = _normalizeRoomCode(roomCode);
    if (!_roomCodePattern.hasMatch(normalizedCode)) return false;
    final existing = await _client
        .from('ck_study_rooms')
        .select('id')
        .eq('room_code', normalizedCode)
        .maybeSingle();
    return existing == null;
  }

  Future<List<StudyRoom>> getMyRooms(String userId) async {
    final membershipRows = await _client
        .from('ck_room_members')
        .select('room_id')
        .eq('user_id', userId);
    final roomIds = (membershipRows as List<dynamic>)
        .map((row) => row['room_id'] as String)
        .toList();
    if (roomIds.isEmpty) return [];
    final rows = await _client
        .from('ck_study_rooms')
        .select()
        .inFilter('id', roomIds)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((row) => StudyRoom.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<StudyRoom>> getOpenRoomsForMentor({
    required String mentorId,
    required String courseId,
  }) async {
    final rows = await _client
        .from('ck_study_rooms')
        .select()
        .eq('mentor_id', mentorId)
        .eq('course_id', courseId)
        .eq('is_open', true)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((row) => StudyRoom.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<RoomMember>> getRoomMembers(String roomId) async {
    final rows = await _client
        .from('ck_room_members')
        .select('*, ck_profiles(full_name, student_id)')
        .eq('room_id', roomId)
        .order('joined_at');
    return (rows as List<dynamic>)
        .map((row) => RoomMember.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<StudyRoom> getRoom(String roomId) async {
    final row = await _client
        .from('ck_study_rooms')
        .select()
        .eq('id', roomId)
        .single();
    return StudyRoom.fromJson(row);
  }

  Future<void> removeMember({
    required String roomId,
    required String userId,
    required String requestedById,
  }) async {
    final room = await getRoom(roomId);
    if (room.mentorId != requestedById && requestedById != userId) {
      throw StateError('Chỉ Mentor mới có thể xóa thành viên khác');
    }
    if (userId == room.mentorId) {
      throw StateError('Không thể xóa Mentor phụ trách khỏi phòng');
    }
    final member = await _client
        .from('ck_room_members')
        .select('id')
        .eq('room_id', roomId)
        .eq('user_id', userId)
        .maybeSingle();
    if (member == null) {
      throw StateError('Thành viên không tồn tại trong phòng');
    }
    final deleted = await _client
        .from('ck_room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', userId)
        .select('id')
        .maybeSingle();
    if (deleted == null) {
      throw StateError('Thành viên đã bị xóa trước khi hoàn tất thao tác');
    }
  }

  Future<void> addMember({
    required String roomId,
    required String userId,
    required String role,
    required String addedById,
  }) async {
    final room = await getRoom(roomId);
    if (addedById != room.mentorId) {
      throw StateError('Chỉ Mentor phụ trách mới có thể thêm thành viên');
    }
    await _addRoomMember(room: room, userId: userId, role: role);
  }

  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    await removeMember(
      roomId: roomId,
      userId: userId,
      requestedById: userId,
    );
  }

  Future<StudyRoom> joinRoomByCode({
    required String roomCode,
    required String userId,
  }) async {
    final normalizedCode = _normalizeRoomCode(roomCode);
    if (!_roomCodePattern.hasMatch(normalizedCode)) {
      throw const FormatException('Mã phòng phải gồm 6 ký tự hợp lệ');
    }
    final response = await _client
        .from('ck_study_rooms')
        .select()
        .eq('room_code', normalizedCode)
        .maybeSingle();
    if (response == null) {
      throw StateError('Mã phòng không tồn tại');
    }
    final room = StudyRoom.fromJson(response);
    await _client.from('ck_room_members').upsert({
      'room_id': room.id,
      'user_id': userId,
      'role': 'mentee',
    }, onConflict: 'room_id,user_id');
    await NotificationService().createNotification(
      userId: room.mentorId,
      title: 'Học viên mới tham gia phòng',
      body: 'Có học viên vừa tham gia phòng "${room.name}" bằng mã phòng.',
      type: 'joined',
      roomId: room.id,
    );
    return room;
  }

  Future<void> sendInvitation({
    required String roomId,
    required String senderId,
    required String receiverId,
  }) async {
    final room = await getRoom(roomId);
    if (!room.isOpen) throw StateError('Phòng học đã đóng');
    if (room.mentorId != senderId) {
      throw StateError('Chỉ Mentor phụ trách mới có thể gửi lời mời');
    }
    if (receiverId == senderId) {
      throw ArgumentError('Không thể gửi lời mời cho chính mình');
    }
    await _ensureCourseRegistration(
      userId: receiverId,
      courseId: room.courseId,
      role: 'mentee',
    );
    await _ensureNotRoomMember(roomId: roomId, userId: receiverId);
    await _ensureNoOtherCourseRoomMembership(
      room: room,
      userId: receiverId,
    );
    await _ensureRoomHasCapacity(room);
    await _ensureNoPendingInvitation(
      roomId: roomId,
      senderId: senderId,
      receiverId: receiverId,
    );
    await _client.from('ck_room_invitations').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'type': 'invite',
    });
    await NotificationService().createNotification(
      userId: receiverId,
      title: 'Lời mời tham gia phòng học',
      body: 'Bạn nhận được lời mời tham gia phòng học mới từ Mentor.',
      type: 'invitation',
      roomId: roomId,
    );
  }

  Future<void> requestToJoin({
    required String roomId,
    required String menteeId,
  }) async {
    final room = await _client
        .from('ck_study_rooms')
        .select()
        .eq('id', roomId)
        .single();
    final studyRoom = StudyRoom.fromJson(room);
    if (!studyRoom.isOpen) throw StateError('Phòng học đã đóng');
    if (studyRoom.mentorId == menteeId) {
      throw ArgumentError('Mentor không thể gửi yêu cầu vào phòng của mình');
    }
    await _ensureCourseRegistration(
      userId: menteeId,
      courseId: studyRoom.courseId,
      role: 'mentee',
    );
    await _ensureNotRoomMember(roomId: roomId, userId: menteeId);
    await _ensureNoOtherCourseRoomMembership(
      room: studyRoom,
      userId: menteeId,
    );
    await _ensureRoomHasCapacity(studyRoom);
    await _ensureNoPendingInvitation(
      roomId: roomId,
      senderId: menteeId,
      receiverId: studyRoom.mentorId,
    );
    await _client.from('ck_room_invitations').insert({
      'room_id': roomId,
      'sender_id': menteeId,
      'receiver_id': studyRoom.mentorId,
      'type': 'request',
    });
  }

  Future<List<RoomInvitation>> getMyInvitations(String userId) async {
    final rows = await _client
        .from('ck_room_invitations')
        .select('*, ck_study_rooms(name)')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((row) => RoomInvitation.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> respondToInvitation({
    required String invitationId,
    required String responderId,
    required bool accept,
  }) async {
    final invitation = await _client
        .from('ck_room_invitations')
        .select()
        .eq('id', invitationId)
        .eq('receiver_id', responderId)
        .eq('status', 'pending')
        .maybeSingle();
    if (invitation == null) {
      throw StateError('Lời mời không tồn tại, đã xử lý hoặc không thuộc về bạn');
    }

    final type = invitation['type'] as String?;
    if (type != 'invite' && type != 'request') {
      throw StateError('Loại lời mời không hợp lệ');
    }
    final roomId = invitation['room_id'] as String;
    final room = await getRoom(roomId);
    final senderId = invitation['sender_id'] as String;
    if (type == 'invite' && room.mentorId != senderId) {
      throw StateError('Lời mời không được gửi bởi Mentor phụ trách');
    }
    if (type == 'request' &&
        (room.mentorId != responderId || senderId == room.mentorId)) {
      throw StateError('Yêu cầu tham gia không hợp lệ');
    }
    if (accept && !room.isOpen) {
      throw StateError('Không thể chấp nhận lời mời vào phòng đã đóng');
    }

    final response = await _client
        .from('ck_room_invitations')
        .update({
          'status': accept ? 'accepted' : 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', invitationId)
        .eq('receiver_id', responderId)
        .eq('status', 'pending')
        .select()
        .maybeSingle();
    if (response == null) {
      throw StateError('Lời mời không còn ở trạng thái chờ xử lý');
    }
    if (!accept) return;
    final menteeId = response['type'] == 'request'
        ? response['sender_id']
        : response['receiver_id'];
    await _client.from('ck_room_members').upsert({
      'room_id': response['room_id'],
      'user_id': menteeId,
      'role': 'mentee',
    }, onConflict: 'room_id,user_id');
    final notifRoomId = response['room_id'] as String?;
    final notifSenderId = response['sender_id'] as String?;
    if (notifSenderId != null) {
      final isRequest = response['type'] == 'request';
      await NotificationService().createNotification(
        userId: notifSenderId,
        title: isRequest
            ? 'Yêu cầu tham gia được chấp nhận'
            : 'Mentee đã chấp nhận lời mời',
        body: isRequest
            ? 'Mentor đã duyệt yêu cầu tham gia phòng học của bạn.'
            : 'Một học viên đã chấp nhận lời mời tham gia phòng học.',
        type: 'accepted',
        roomId: notifRoomId,
      );
    }
  }

  String _generateRoomCode() {
    return List.generate(
      _roomCodeLength,
      (_) => _roomCodeCharacters[_random.nextInt(_roomCodeCharacters.length)],
    ).join();
  }

  String _normalizeRoomCode(String roomCode) =>
      roomCode.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

  Future<void> _ensureNotRoomMember({
    required String roomId,
    required String userId,
  }) async {
    final member = await _client
        .from('ck_room_members')
        .select('id')
        .eq('room_id', roomId)
        .eq('user_id', userId)
        .maybeSingle();
    if (member != null) throw StateError('Bạn đã là thành viên của phòng này');
  }

  Future<void> _ensureNoPendingInvitation({
    required String roomId,
    required String senderId,
    required String receiverId,
  }) async {
    final directRows = await _client
        .from('ck_room_invitations')
        .select('id')
        .eq('room_id', roomId)
        .eq('sender_id', senderId)
        .eq('receiver_id', receiverId)
        .eq('status', 'pending')
        .limit(1);
    final reverseRows = directRows.isEmpty
        ? await _client
            .from('ck_room_invitations')
            .select('id')
            .eq('room_id', roomId)
            .eq('sender_id', receiverId)
            .eq('receiver_id', senderId)
            .eq('status', 'pending')
            .limit(1)
        : <dynamic>[];
    if (directRows.isNotEmpty || reverseRows.isNotEmpty) {
      throw StateError('Đã có lời mời đang chờ xử lý');
    }
  }

  Future<void> _ensureNoOtherCourseRoomMembership({
    required StudyRoom room,
    required String userId,
  }) async {
    final memberships = await _client
        .from('ck_room_members')
        .select('room_id')
        .eq('user_id', userId);
    final roomIds = (memberships as List<dynamic>)
        .map((row) => row['room_id'] as String)
        .where((roomId) => roomId != room.id)
        .toList();
    if (roomIds.isEmpty) return;
    final otherRooms = await _client
        .from('ck_study_rooms')
        .select('id')
        .inFilter('id', roomIds)
        .eq('course_id', room.courseId);
    if ((otherRooms as List<dynamic>).isNotEmpty) {
      throw StateError('Bạn đã tham gia một phòng khác của học phần này');
    }
  }

  Future<void> _ensureRoomHasCapacity(StudyRoom room) async {
    final registration = await _client
        .from('ck_program_registrations')
        .select('max_mentees')
        .eq('user_id', room.mentorId)
        .eq('course_id', room.courseId)
        .eq('role', 'mentor')
        .maybeSingle();
    final maxMentees = registration?['max_mentees'] as int? ?? 5;
    final menteeCount = (await _getRoomMenteeCounts(
      mentorIds: [room.mentorId],
      courseId: room.courseId,
    ))[room.mentorId] ?? 0;
    if (menteeCount >= maxMentees) {
      throw StateError('Mentor đã đạt giới hạn số lượng Mentee');
    }
  }

  Future<void> _ensureCourseRegistration({
    required String userId,
    required String courseId,
    required String role,
  }) async {
    final registration = await _client
        .from('ck_program_registrations')
        .select('id')
        .eq('user_id', userId)
        .eq('course_id', courseId)
        .eq('role', role)
        .maybeSingle();
    if (registration == null) {
      throw StateError('Người dùng chưa đăng ký vai trò $role cho học phần này');
    }
  }

  Future<void> _addRoomMember({
    required StudyRoom room,
    required String userId,
    required String role,
  }) async {
    if (role != 'mentor' && role != 'mentee') {
      throw ArgumentError.value(role, 'role', 'Vai trò không hợp lệ');
    }
    if (!room.isOpen) throw StateError('Phòng học đã đóng');
    if (role == 'mentor' && userId != room.mentorId) {
      throw StateError('Mentor thành viên phải là Mentor phụ trách phòng');
    }
    if (role == 'mentee' && userId == room.mentorId) {
      throw StateError('Mentor không thể được thêm vào phòng với vai trò Mentee');
    }
    final existing = await _client
        .from('ck_room_members')
        .select('role')
        .eq('room_id', room.id)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null) {
      if (existing['role'] != role) {
        throw StateError('Thành viên đã tồn tại với vai trò khác');
      }
      return;
    }
    if (role == 'mentee') {
      await _ensureCourseRegistration(
        userId: userId,
        courseId: room.courseId,
        role: 'mentee',
      );
      await _ensureNoOtherCourseRoomMembership(room: room, userId: userId);
      await _ensureRoomHasCapacity(room);
    }
    try {
      await _client.from('ck_room_members').insert({
        'room_id': room.id,
        'user_id': userId,
        'role': role,
      });
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
      final racedMember = await _client
          .from('ck_room_members')
          .select('role')
          .eq('room_id', room.id)
          .eq('user_id', userId)
          .maybeSingle();
      if (racedMember?['role'] != role) rethrow;
    }
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
