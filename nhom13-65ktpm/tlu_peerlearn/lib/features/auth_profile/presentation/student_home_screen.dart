import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../../room_matching/data/room_matching_repository.dart';
import '../data/auth_repository.dart';
import '../data/registration_repository.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final regsAsync = ref.watch(myRegistrationsProvider);
    final profile = profileAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TLU PeerLearn'),
        actions: [
          if (profile != null)
            Consumer(
              builder: (context, ref, _) {
                final notifs =
                    ref.watch(userNotificationsProvider(profile.id)).value ??
                        [];
                final unread = notifs.where((n) => !n.isRead).length;
                return IconButton(
                  tooltip: 'Thông báo',
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            NotificationsScreen(userId: profile.id),
                      ),
                    );
                  },
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Hồ sơ cá nhân',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentProfileProvider);
          ref.invalidate(myRegistrationsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsiveContainer(
            maxWidth: 960,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, ${profile?.fullName ?? 'Sinh viên'}!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.studentId != null
                          ? 'MSV: ${profile!.studentId} • ${profile.className ?? 'Sinh viên TLU'}'
                          : 'Hãy cập nhật đầy đủ hồ sơ cá nhân để bắt đầu.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chức năng chính',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisExtent: 120,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ActionCard(
                  icon: Icons.app_registration,
                  title: 'Đăng ký Mentor / Mentee',
                  subtitle: 'Chọn học phần & lịch rảnh',
                  onTap: () => context.push('/registrations'),
                ),
                _ActionCard(
                  icon: Icons.groups_outlined,
                  title: 'Phòng học & Ghép đôi',
                  subtitle: 'Tìm Mentor/Mentee, tạo & vào phòng',
                  onTap: () => context.push('/rooms'),
                ),
                _ActionCard(
                  icon: Icons.person_outline,
                  title: 'Hồ sơ cá nhân',
                  subtitle: 'Cập nhật MSV, khoa, lớp',
                  onTap: () => context.push('/profile'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (profile != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Phòng học của tôi',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.push('/rooms'),
                    child: const Text('Tìm / Tạo phòng'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ref.watch(myRoomsProvider(profile.id)).when(
                    data: (rooms) {
                      if (rooms.isEmpty) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.meeting_room_outlined),
                            title: const Text('Bạn chưa tham gia phòng học nào'),
                            subtitle: const Text('Bấm để tìm Mentor/Mentee hoặc nhập mã phòng'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/rooms'),
                          ),
                        );
                      }
                      return Column(
                        children: rooms.map((room) {
                          return Card(
                            child: ListTile(
                              onTap: () => context.push('/rooms/${room.id}'),
                              leading: const Icon(Icons.meeting_room_outlined),
                              title: Text(room.name),
                              subtitle: Text('Mã phòng: ${room.roomCode}'),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Lỗi tải phòng học: $e'),
                  ),
              const SizedBox(height: 24),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Học phần đã đăng ký',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.push('/registrations'),
                  child: const Text('Đăng ký thêm'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            regsAsync.when(
              data: (regs) {
                if (regs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Bạn chưa đăng ký học phần nào.'),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            onPressed: () => context.push('/registrations'),
                            child: const Text('Đăng ký ngay'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: regs.map((r) {
                    return Card(
                      child: ListTile(
                        onTap: () => context.push('/registrations', extra: r),
                        leading: Icon(
                          r.role == 'mentor'
                              ? Icons.school_outlined
                              : Icons.people_outline,
                        ),
                        title: Text(
                            '${r.courseCode ?? ''} - ${r.courseName ?? r.courseId}'),
                        subtitle: Text(
                          'Vai trò: ${r.role.toUpperCase()} • ${r.availableSlots.length} buổi rảnh',
                        ),
                        trailing: const Icon(Icons.edit_outlined, size: 20),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Lỗi tải đăng ký: $e'),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

