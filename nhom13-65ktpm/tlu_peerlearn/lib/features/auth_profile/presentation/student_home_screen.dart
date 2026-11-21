import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        child: ListView(
          padding: const EdgeInsets.all(16),
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
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _ActionCard(
                  icon: Icons.app_registration,
                  title: 'Đăng ký Mentor / Mentee',
                  subtitle: 'Chọn học phần & lịch rảnh',
                  onTap: () => context.push('/registrations'),
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

