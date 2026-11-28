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
  final SupabaseClient _client;
  final Random _random;

  RoomMatchingRepository(this._client) : _random = Random.secure();

  Future<List<CompatibilityMatch>> getMatches({
    required ProgramRegistration current,
  }) async {
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
      final academicScore = CompatibilityScoring.academicFit(
        mentor.courseGrade,
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
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _generateRoomCode();
      try {
        final response = await _client
            .from('ck_study_rooms')
            .insert({
              'course_id': courseId,
              'mentor_id': mentorId,
              'name': name.trim(),
              'description': _nullableTrim(description),
              'room_code': code,
            })
            .select()
            .single();
        final room = StudyRoom.fromJson(response);
        await _client.from('ck_room_members').insert({
          'room_id': room.id,
          'user_id': mentorId,
          'role': 'mentor',
        });
        return room;
      } on PostgrestException catch (error) {
        if (error.code != '23505' || attempt == 4) rethrow;
      }
    }
    throw StateError('Không thể tạo mã phòng duy nhất');
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
  }) async {
    await _client
        .from('ck_room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }

  Future<StudyRoom> joinRoomByCode({
    required String roomCode,
    required String userId,
  }) async {
    final response = await _client
        .from('ck_study_rooms')
        .select()
        .eq('room_code', roomCode.trim().toUpperCase())
        .eq('is_open', true)
        .maybeSingle();
    if (response == null) {
      throw StateError('Không tìm thấy phòng hoặc phòng đã đóng');
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
        .select('mentor_id')
        .eq('id', roomId)
        .single();
    await _client.from('ck_room_invitations').insert({
      'room_id': roomId,
      'sender_id': menteeId,
      'receiver_id': room['mentor_id'] as String,
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
    required bool accept,
  }) async {
    final response = await _client
        .from('ck_room_invitations')
        .update({
          'status': accept ? 'accepted' : 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', invitationId)
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
    final roomId = response['room_id'] as String?;
    final senderId = response['sender_id'] as String?;
    if (senderId != null) {
      final isRequest = response['type'] == 'request';
      await NotificationService().createNotification(
        userId: senderId,
        title: isRequest
            ? 'Yêu cầu tham gia được chấp nhận'
            : 'Mentee đã chấp nhận lời mời',
        body: isRequest
            ? 'Mentor đã duyệt yêu cầu tham gia phòng học của bạn.'
            : 'Một học viên đã chấp nhận lời mời tham gia phòng học.',
        type: 'accepted',
        roomId: roomId,
      );
    }
  }

  String _generateRoomCode() {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (_) => characters[_random.nextInt(characters.length)],
    ).join();
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
