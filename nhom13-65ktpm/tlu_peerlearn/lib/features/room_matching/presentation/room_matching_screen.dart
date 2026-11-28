import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/responsive_container.dart';
import '../../auth_profile/data/auth_repository.dart';
import '../../auth_profile/data/registration_repository.dart';
import '../../auth_profile/domain/program_registration.dart';
import '../data/room_matching_repository.dart';
import '../domain/compatibility_match.dart';
import '../domain/room_invitation.dart';
import '../domain/study_room.dart';
import 'study_room_detail_screen.dart';

class RoomMatchingScreen extends ConsumerStatefulWidget {
  const RoomMatchingScreen({super.key});

  @override
  ConsumerState<RoomMatchingScreen> createState() =>
      _RoomMatchingScreenState();
}

class _RoomMatchingScreenState extends ConsumerState<RoomMatchingScreen> {
  String? _selectedRegistrationId;
  final Map<String, Color> _roomColors = {};
  Future<List<CompatibilityMatch>>? _matchesFuture;
  bool _isCreatingRoom = false;
  bool _isJoiningRoom = false;

  ProgramRegistration? _selectedRegistration(
    List<ProgramRegistration> registrations,
  ) {
    for (final registration in registrations) {
      if (registration.id == _selectedRegistrationId) return registration;
    }
    return registrations.isEmpty ? null : registrations.first;
  }

  void _loadMatches(ProgramRegistration registration) {
    setState(() {
      _selectedRegistrationId = registration.id;
      _matchesFuture = ref
          .read(roomMatchingRepositoryProvider)
          .getMatches(current: registration);
    });
  }

  Future<void> _createRoom(
    String mentorId,
    ProgramRegistration registration,
  ) async {
    final name = TextEditingController();
    final description = TextEditingController();
    Color selectedColor = const Color(0xFF1976D2);
    final palette = [
      const Color(0xFF1976D2),
      const Color(0xFF3949AB),
      const Color(0xFF00897B),
      const Color(0xFF2E7D32),
      const Color(0xFFEF6C00),
      const Color(0xFF7B1FA2),
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: selectedColor.withValues(alpha: 0.15),
                child: Icon(Icons.add_home_work_outlined, color: selectedColor),
              ),
              const SizedBox(width: 10),
              const Text('Tạo phòng học', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Tên phòng',
                    hintText: 'VD: Nhóm Ôn Tập 01',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    hintText: 'Mục tiêu học tập, lịch dự kiến...',
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Chọn màu badge phòng',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: palette.map((c) {
                    final isSelected = c == selectedColor;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedColor = c),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black87, width: 2.5)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: selectedColor),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tạo phòng'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      name.dispose();
      description.dispose();
      return;
    }
    if (name.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập tên phòng');
      name.dispose();
      description.dispose();
      return;
    }
    setState(() => _isCreatingRoom = true);
    try {
      final room = await ref.read(roomMatchingRepositoryProvider).createRoom(
            courseId: registration.courseId,
            mentorId: mentorId,
            name: name.text,
            description: description.text,
          );
      ref.invalidate(myRoomsProvider(mentorId));
      if (mounted) _openRoom(room);
    } catch (error) {
      _showMessage('Không thể tạo phòng: $error');
    } finally {
      name.dispose();
      description.dispose();
      if (mounted) setState(() => _isCreatingRoom = false);
    }
  }

  Future<void> _joinRoom(String userId) async {
    final code = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tham gia phòng học'),
        content: TextField(
          controller: code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Room Code'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tham gia'),
          ),
        ],
      ),
    );
    if (confirmed != true || code.text.trim().isEmpty) {
      code.dispose();
      return;
    }
    setState(() => _isJoiningRoom = true);
    try {
      final room = await ref
          .read(roomMatchingRepositoryProvider)
          .joinRoomByCode(roomCode: code.text, userId: userId);
      ref.invalidate(myRoomsProvider(userId));
      if (mounted) _openRoom(room);
    } catch (error) {
      _showMessage('Không thể tham gia phòng: $error');
    } finally {
      code.dispose();
      if (mounted) setState(() => _isJoiningRoom = false);
    }
  }

  Future<void> _sendInvitation({
    required String userId,
    required ProgramRegistration current,
    required CompatibilityMatch match,
  }) async {
    try {
      final repository = ref.read(roomMatchingRepositoryProvider);
      final rooms = current.role == 'mentor'
          ? await repository.getOpenRoomsForMentor(
              mentorId: userId,
              courseId: current.courseId,
            )
          : await repository.getOpenRoomsForMentor(
              mentorId: match.userId,
              courseId: current.courseId,
            );
      if (rooms.isEmpty) {
        _showMessage(
          current.role == 'mentor'
              ? 'Vui lòng mở phòng học cho học phần này trước khi mời học viên vào phòng.'
              : 'Mentor này chưa mở phòng học nào cho học phần này.',
        );
        return;
      }
      if (!mounted) return;
      final room = await showDialog<StudyRoom>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Icon(
                Icons.meeting_room_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  current.role == 'mentor'
                      ? 'Chọn phòng để mời'
                      : 'Chọn phòng để xin tham gia',
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: rooms
                  .map(
                    (room) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Icon(
                            Icons.groups_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          room.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Mã phòng: ${room.roomCode}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, room),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      if (room == null) return;
      if (current.role == 'mentor') {
        await repository.sendInvitation(
          roomId: room.id,
          senderId: userId,
          receiverId: match.userId,
        );
      } else {
        await repository.requestToJoin(roomId: room.id, menteeId: userId);
      }
      _showMessage(current.role == 'mentor' ? 'Đã gửi lời mời' : 'Đã gửi yêu cầu tham gia');
      ref.invalidate(myInvitationsProvider(userId));
    } catch (error) {
      _showMessage('Không thể gửi lời mời: $error');
    }
  }

  void _openRoom(StudyRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyRoomDetailScreen(roomId: room.id),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final registrationsAsync = ref.watch(myRegistrationsProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gợi ý kết nối & Phòng học'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: [
              Tab(text: 'Gợi ý'),
              Tab(text: 'Lời mời'),
              Tab(text: 'Phòng học'),
            ],
          ),
          actions: [
            if (profileAsync.value != null)
              IconButton(
                tooltip: 'Tham gia bằng mã phòng',
                onPressed: _isJoiningRoom
                    ? null
                    : () => _joinRoom(profileAsync.value!.id),
                icon: _isJoiningRoom
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.vpn_key),
              ),
          ],
        ),
        body: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Lỗi hồ sơ: $error')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Vui lòng đăng nhập'));
            }
            return registrationsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Lỗi đăng ký: $error')),
              data: (registrations) => ResponsiveContainer(
                maxWidth: 960,
                padding: EdgeInsets.zero,
                child: TabBarView(
                  children: [
                    _buildMatches(profile.id, registrations),
                    _buildInvitations(profile.id),
                    _buildRooms(profile.id),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMatches(
    String userId,
    List<ProgramRegistration> registrations,
  ) {
    if (registrations.isEmpty) {
      return const Center(
        child: Text('Đăng ký học phần và vai trò để xem gợi ý kết nối'),
      );
    }
    final registration = _selectedRegistration(registrations)!;
    _matchesFuture ??= ref
        .read(roomMatchingRepositoryProvider)
        .getMatches(current: registration);
    final hasMentorRole = registrations.any((item) =>
        item.courseId == registration.courseId && item.role == 'mentor');
    final myRooms = ref.watch(myRoomsProvider(userId)).value ?? const <StudyRoom>[];
    final alreadyInCourseRoom = registration.role == 'mentee' &&
        myRooms.any((r) => r.courseId == registration.courseId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          initialValue: registration.id,
          decoration: const InputDecoration(labelText: 'Học phần'),
          items: registrations.map((item) {
            final label = [
              if ((item.courseCode ?? '').isNotEmpty) item.courseCode!,
              if ((item.courseName ?? '').isNotEmpty) item.courseName!,
            ].join(' - ');
            return DropdownMenuItem(
              value: item.id,
              child: Text(
                label.isEmpty ? item.courseId : label,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (id) {
            final next = registrations.firstWhere((item) => item.id == id);
            _loadMatches(next);
          },
        ),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  registration.role == 'mentor'
                      ? Icons.school_outlined
                      : Icons.person_outline,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    registration.role == 'mentor'
                        ? 'Vai trò của bạn: Mentor — Gợi ý Mentee phù hợp để mời vào phòng'
                        : alreadyInCourseRoom
                            ? 'Bạn đã tham gia phòng học cho học phần này'
                            : 'Vai trò của bạn: Mentee — Gợi ý Mentor phù hợp để xin vào phòng',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (hasMentorRole)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: _isCreatingRoom
                  ? null
                  : () => _createRoom(userId, registration),
              icon: const Icon(Icons.add),
              label: const Text('Tạo phòng'),
            ),
          ),
        FutureBuilder<List<CompatibilityMatch>>(
          future: _matchesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text('Lỗi tải gợi ý: ${snapshot.error}');
            }
            final matches = snapshot.data ?? const <CompatibilityMatch>[];
            if (matches.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Chưa có người học phù hợp cho học phần này'),
                ),
              );
            }
            return Column(
              children: matches
                  .map((match) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            match.role == 'mentor'
                                ? Icons.school_outlined
                                : Icons.person_outline,
                          ),
                        ),
                        title: Text(match.fullName),
                        subtitle: Text(
                          '${match.role == 'mentor' ? 'Mentor' : 'Mentee'}'
                          ' • Khung giờ trùng: ${(match.timeScore * 100).round()}%',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Phù hợp ${match.percentage}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (alreadyInCourseRoom) ...[
                              if (myRooms.any((r) =>
                                  r.courseId == registration.courseId &&
                                  r.mentorId == match.userId))
                                const Tooltip(
                                  message:
                                      'Bạn đã tham gia phòng học của Mentor này',
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                ),
                            ] else if ((ref
                                        .watch(myInvitationsProvider(userId))
                                        .value ??
                                    const [])
                                .any((inv) =>
                                    inv.status == 'pending' &&
                                    ((inv.senderId == userId &&
                                            inv.receiverId == match.userId) ||
                                        (inv.receiverId == userId &&
                                            inv.senderId == match.userId))))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Đã gửi lời mời',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                tooltip: registration.role == 'mentor'
                                    ? 'Mời vào phòng'
                                    : 'Xin tham gia phòng',
                                icon: const Icon(Icons.send_outlined),
                                onPressed: () => _sendInvitation(
                                  userId: userId,
                                  current: registration,
                                  match: match,
                                ),
                              ),
                          ],
                        ),
                      ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInvitations(String userId) {
    final invitationAsync = ref.watch(myInvitationsProvider(userId));
    return invitationAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Lỗi tải lời mời: $error')),
      data: (invitations) {
        if (invitations.isEmpty) {
          return const Center(child: Text('Chưa có lời mời nào'));
        }
        final userIds = invitations
            .expand((i) => [i.senderId, i.receiverId])
            .toSet()
            .toList();
        return FutureBuilder<Map<String, String>>(
          future: _fetchProfileNames(userIds),
          builder: (context, nameSnap) {
            final names = nameSnap.data ?? const {};
            return ListView(
              padding: const EdgeInsets.all(16),
              children: invitations.map((invitation) {
                final isIncoming = invitation.receiverId == userId;
                final targetId =
                    isIncoming ? invitation.senderId : invitation.receiverId;
                final targetName = names[targetId] ?? 'Thành viên';
                final pending = invitation.status == 'pending';
                final statusLabel = switch (invitation.status) {
                  'pending' => 'Đang chờ',
                  'accepted' => 'Đã chấp nhận',
                  'rejected' => 'Đã từ chối',
                  _ => invitation.status,
                };
                final statusColor = switch (invitation.status) {
                  'pending' => Colors.orange,
                  'accepted' => Colors.green,
                  'rejected' => Colors.red,
                  _ => Colors.grey,
                };
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                      child: Icon(
                        isIncoming
                            ? Icons.move_to_inbox_outlined
                            : Icons.send_outlined,
                        color: statusColor,
                      ),
                    ),
                    title: Text(
                      invitation.roomName ?? 'Phòng học',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${isIncoming ? 'Từ' : 'Gửi tới'}: $targetName',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                trailing: isIncoming && pending
                    ? Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Từ chối',
                            onPressed: () => _respond(userId, invitation, false),
                            icon: const Icon(Icons.close),
                          ),
                          IconButton(
                            tooltip: 'Chấp nhận',
                            onPressed: () => _respond(userId, invitation, true),
                            icon: const Icon(Icons.check),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          }).toList(),
        );
          },
        );
      },
    );
  }

  Future<void> _respond(
    String userId,
    RoomInvitation invitation,
    bool accept,
  ) async {
    try {
      await ref.read(roomMatchingRepositoryProvider).respondToInvitation(
            invitationId: invitation.id,
            responderId: userId,
            accept: accept,
          );
      ref.invalidate(myInvitationsProvider(userId));
      ref.invalidate(myRoomsProvider(userId));
      _showMessage(accept ? 'Đã chấp nhận lời mời' : 'Đã từ chối lời mời');
    } catch (error) {
      _showMessage('Không thể xử lý lời mời: $error');
    }
  }

  Widget _buildRooms(String userId) {
    final roomsAsync = ref.watch(myRoomsProvider(userId));
    return roomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Lỗi tải phòng học: $error')),
      data: (rooms) {
        if (rooms.isEmpty) {
          return const Center(child: Text('Bạn chưa tham gia phòng học nào'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myRoomsProvider(userId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: rooms
                .map((room) {
                  const palette = [
                    Color(0xFF1976D2),
                    Color(0xFF3949AB),
                    Color(0xFF00897B),
                    Color(0xFF2E7D32),
                    Color(0xFFEF6C00),
                    Color(0xFF7B1FA2),
                  ];
                  final roomColor = _roomColors[room.id] ??
                      palette[room.id.hashCode.abs() % palette.length];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: roomColor.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.meeting_room_outlined,
                          color: roomColor,
                        ),
                      ),
                      title: Text(
                        room.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: roomColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Mã phòng: ${room.roomCode}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: roomColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openRoom(room),
                    ),
                  );
                })
                .toList(),
          ),
        );
      },
    );
  }
}

Future<Map<String, String>> _fetchProfileNames(List<String> userIds) async {
  if (userIds.isEmpty) return {};
  final Map<String, String> names = {};
  for (final table in ['ck_profiles', 'profiles']) {
    try {
      final rows = await Supabase.instance.client
          .from(table)
          .select('id, full_name')
          .inFilter('id', userIds);
      for (final r in rows as List<dynamic>) {
        final id = r['id'] as String?;
        final name = r['full_name'] as String?;
        if (id != null && name != null && name.isNotEmpty) {
          names[id] = name;
        }
      }
      if (names.isNotEmpty) break;
    } catch (_) {}
  }
  return names;
}
