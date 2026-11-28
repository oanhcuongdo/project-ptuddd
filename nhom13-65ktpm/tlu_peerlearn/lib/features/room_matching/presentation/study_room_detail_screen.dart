import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/responsive_container.dart';
import '../../auth_profile/data/auth_repository.dart';
import '../../documents/screens/room_documents_tab.dart';
import '../../practice_stats/screens/room_practice_tab.dart';
import '../../sessions/screens/room_sessions_tab.dart';
import '../data/room_matching_repository.dart';
import '../domain/room_member.dart';
import '../domain/study_room.dart';

class StudyRoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;

  const StudyRoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<StudyRoomDetailScreen> createState() =>
      _StudyRoomDetailScreenState();
}

class _StudyRoomDetailScreenState extends ConsumerState<StudyRoomDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(studyRoomProvider(widget.roomId));
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.value;
    final userId = profile?.id;
    final isAdmin = profile?.role == 'admin';
    return roomAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Phòng học')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Phòng học')),
        body: Center(child: Text('Không thể tải phòng học: $error')),
      ),
      data: (room) => _buildRoomTabs(room, userId, isAdmin: isAdmin),
    );
  }

  Widget _buildRoomTabs(
    StudyRoom room,
    String? userId, {
    required bool isAdmin,
  }) {
    final isMentor = room.mentorId == userId;
    final tabs = isAdmin
        ? const [
            Tab(text: 'Tổng quan / Thành viên'),
            Tab(text: 'Buổi học'),
          ]
        : const [
            Tab(text: 'Tổng quan / Thành viên'),
            Tab(text: 'Tài liệu'),
            Tab(text: 'Ôn tập'),
            Tab(text: 'Buổi học'),
          ];

    final tabViews = isAdmin
        ? [
            _RoomOverview(room: room, currentUserId: userId),
            RoomSessionsTab(
              roomId: room.id,
              currentUserId: userId,
              isMentor: false,
            ),
          ]
        : [
            _RoomOverview(room: room, currentUserId: userId),
            RoomDocumentsTab(
              roomId: room.id,
              currentUserId: userId,
              isMentor: isMentor,
            ),
            RoomPracticeTab(
              roomId: room.id,
              currentUserId: userId,
              isMentor: isMentor,
            ),
            RoomSessionsTab(
              roomId: room.id,
              currentUserId: userId,
              isMentor: isMentor,
            ),
          ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(room.name),
          bottom: TabBar(
            isScrollable: true,
            tabs: tabs,
          ),
        ),
        body: ResponsiveContainer(
          maxWidth: 960,
          padding: EdgeInsets.zero,
          child: TabBarView(children: tabViews),
        ),
      ),
    );
  }
}

class _RoomOverview extends ConsumerWidget {
  final StudyRoom room;
  final String? currentUserId;

  const _RoomOverview({required this.room, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(roomMembersProvider(room.id));
    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Lỗi tải thành viên: $error')),
      data: (members) {
        final mentors = members.where((m) => m.role == 'mentor').toList();
        final mentees = members.where((m) => m.role != 'mentor').toList()
          ..sort((a, b) {
            if (a.userId == currentUserId) return -1;
            if (b.userId == currentUserId) return 1;
            return 0;
          });
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(roomMembersProvider(room.id)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if ((room.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(room.description!),
                      ],
                      const SizedBox(height: 8),
                      SelectableText('Mã phòng: ${room.roomCode}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mentor phụ trách',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (mentors.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Thông tin Mentor chưa sẵn sàng'),
                  ),
                )
              else
                ...mentors.map(
                  (member) => _MemberTile(
                    member: member,
                    isCurrentUser: member.userId == currentUserId,
                    canManage: false,
                    onRemove: () {},
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Học viên (${mentees.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (mentees.isEmpty)
                const Card(child: ListTile(title: Text('Chưa có học viên nào'))),
              ...mentees.map(
                (member) => _MemberTile(
                  member: member,
                  isCurrentUser: member.userId == currentUserId,
                  canManage:
                      currentUserId == room.mentorId &&
                      member.userId != room.mentorId,
                  onRemove: () => _removeMember(context, ref, member),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    RoomMember member,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thành viên?'),
        content: Text(
          'Bạn muốn xóa ${member.fullName ?? 'thành viên này'} khỏi phòng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref
          .read(roomMatchingRepositoryProvider)
          .removeMember(roomId: room.id, userId: member.userId);
      ref.invalidate(roomMembersProvider(room.id));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa thành viên: $error')),
        );
      }
    }
  }
}

class _MemberTile extends StatelessWidget {
  final RoomMember member;
  final bool isCurrentUser;
  final bool canManage;
  final VoidCallback onRemove;

  const _MemberTile({
    required this.member,
    this.isCurrentUser = false,
    required this.canManage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isMentor = member.role == 'mentor';
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: isCurrentUser
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      shape: isCurrentUser
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.primary, width: 1.5),
            )
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isMentor ? colorScheme.primaryContainer : colorScheme.secondaryContainer,
          child: Icon(
            isMentor ? Icons.school_outlined : Icons.person,
            color: isMentor
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSecondaryContainer,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                member.fullName ?? member.userId,
                style: isCurrentUser
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : null,
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bạn',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isMentor
                    ? colorScheme.primaryContainer
                    : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isMentor ? 'Mentor' : 'Mentee',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isMentor
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
          ],
        ),
        subtitle: member.studentId == null ? null : Text('MSV: ${member.studentId}'),
        trailing: canManage
            ? IconButton(
                tooltip: 'Xóa thành viên',
                onPressed: onRemove,
                icon: const Icon(Icons.person_remove_outlined),
              )
            : null,
      ),
    );
  }
}
