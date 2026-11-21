import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth_profile/data/auth_repository.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  final AdminOverviewStats? initialStats;
  final List<AdminRoomSummary>? initialRooms;

  const AdminDashboardScreen({
    super.key,
    this.initialStats,
    this.initialRooms,
  });

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final statsAsync = widget.initialStats != null
        ? AsyncValue.data(widget.initialStats!)
        : ref.watch(adminOverviewStatsProvider);
    final roomsAsync = widget.initialRooms != null
        ? AsyncValue.data(widget.initialRooms!)
        : ref.watch(adminRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Giám Sát'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: 'Nhật ký & Minh chứng',
            onPressed: () => context.push('/admin/sessions'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminOverviewStatsProvider);
          ref.invalidate(adminRoomsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Tổng quan chương trình',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            statsAsync.when(
              data: (stats) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: [
                  _StatCard(
                      label: 'Mentor',
                      value: '${stats.totalMentors}',
                      icon: Icons.school_outlined),
                  _StatCard(
                      label: 'Mentee',
                      value: '${stats.totalMentees}',
                      icon: Icons.people_outline),
                  _StatCard(
                      label: 'Phòng học',
                      value: '${stats.totalRooms}',
                      icon: Icons.meeting_room_outlined),
                  _StatCard(
                      label: 'Buổi hỗ trợ',
                      value: '${stats.totalSessions}',
                      icon: Icons.event_note_outlined),
                  _StatCard(
                      label: 'Bộ Flashcard/Quiz',
                      value: '${stats.totalGeneratedSets}',
                      icon: Icons.auto_awesome_outlined),
                  _StatCard(
                      label: 'Lượt làm Quiz',
                      value: '${stats.totalQuizAttempts}',
                      icon: Icons.quiz_outlined),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Lỗi tải thống kê: $e'),
            ),
            const SizedBox(height: 24),
            Text(
              'Danh sách Phòng học',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên phòng, học phần hoặc Mentor...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 12),
            roomsAsync.when(
              data: (rooms) {
                final filtered = rooms.where((r) {
                  if (_searchQuery.isEmpty) return true;
                  return r.name.toLowerCase().contains(_searchQuery) ||
                      r.mentorName.toLowerCase().contains(_searchQuery) ||
                      r.courseName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Không tìm thấy phòng học nào.',
                        textAlign: TextAlign.center),
                  );
                }

                return Column(
                  children: filtered.map((room) {
                    return Card(
                      child: ListTile(
                        title: Text(room.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${room.courseName} • Mentor: ${room.mentorName}'),
                        trailing: Chip(
                          label: Text(room.isOpen ? 'Mở' : 'Riêng tư',
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Lỗi tải phòng học: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
