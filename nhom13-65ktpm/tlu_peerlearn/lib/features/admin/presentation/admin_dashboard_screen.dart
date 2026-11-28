import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/gradient_header_banner.dart';
import '../../../core/widgets/responsive_container.dart';
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
  String? _selectedCourse;
  String? _selectedMentor;

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
            tooltip: 'Đăng xuất',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminOverviewStatsProvider);
          ref.invalidate(adminRoomsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsiveContainer(
            maxWidth: 1140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GradientHeaderBanner(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Bảng điều khiển Admin',
                  subtitle: 'Giám sát hoạt động phòng học, buổi học và minh chứng toàn hệ thống',
                  trailing: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Nhật ký'),
                    onPressed: () => context.push('/admin/sessions'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tổng quan chương trình',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                statsAsync.when(
                  data: (stats) => _buildStatsAndCharts(context, stats),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
                const SizedBox(height: 10),
                roomsAsync.when(
                  data: (rooms) => _buildRoomsSection(context, rooms),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Lỗi tải danh sách phòng: $e'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsAndCharts(BuildContext context, AdminOverviewStats stats) {
    final statCards = [
      _StatCard(
        label: 'Mentor',
        value: '${stats.totalMentors}',
        icon: Icons.school_outlined,
        color: Colors.indigo,
      ),
      _StatCard(
        label: 'Mentee',
        value: '${stats.totalMentees}',
        icon: Icons.people_outline,
        color: Colors.teal,
      ),
      _StatCard(
        label: 'Tổng phòng học',
        value: '${stats.totalRooms}',
        icon: Icons.meeting_room_outlined,
        color: Colors.blue,
      ),
      _StatCard(
        label: 'Phòng đang học',
        value: '${stats.activeRooms}',
        icon: Icons.groups_outlined,
        color: Colors.green,
      ),
      _StatCard(
        label: 'Tổng buổi học',
        value: '${stats.totalSessions}',
        icon: Icons.event_note_outlined,
        color: Colors.deepPurple,
      ),
      _StatCard(
        label: 'Buổi hoàn thành',
        value: '${stats.completedSessions}',
        icon: Icons.verified_outlined,
        color: Colors.orange,
      ),
    ];

    final roomActiveRate =
        stats.totalRooms == 0 ? 0.0 : stats.activeRooms / stats.totalRooms;
    final sessionDoneRate = stats.totalSessions == 0
        ? 0.0
        : stats.completedSessions / stats.totalSessions;
    final totalUsers = stats.totalMentors + stats.totalMentees;
    final mentorRate = totalUsers == 0 ? 0.0 : stats.totalMentors / totalUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cols = width >= 960 ? 6 : (width >= 560 ? 3 : 2);
            return GridView.count(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: cols == 6 ? 1.45 : (cols == 3 ? 1.9 : 1.7),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: statCards,
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 680;
            final charts = [
              _DonutChartCard(
                title: 'Phòng đang hoạt động',
                subtitle: '${stats.activeRooms}/${stats.totalRooms} phòng',
                ratio: roomActiveRate,
                color: Colors.blue,
              ),
              _DonutChartCard(
                title: 'Buổi học hoàn thành',
                subtitle:
                    '${stats.completedSessions}/${stats.totalSessions} buổi',
                ratio: sessionDoneRate,
                color: Colors.green,
              ),
              _DonutChartCard(
                title: 'Tỉ lệ Mentor / Tổng TV',
                subtitle:
                    '${stats.totalMentors} Mentor • ${stats.totalMentees} Mentee',
                ratio: mentorRate,
                color: Colors.indigo,
              ),
            ];
            if (isWide) {
              return Row(
                children: [
                  for (var i = 0; i < charts.length; i++) ...[
                    Expanded(child: charts[i]),
                    if (i < charts.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (var i = 0; i < charts.length; i++) ...[
                  charts[i],
                  if (i < charts.length - 1) const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoomsSection(
    BuildContext context,
    List<AdminRoomSummary> rooms,
  ) {
    final courses = rooms.map((r) => r.courseName).toSet().toList()..sort();
    final mentors = rooms.map((r) => r.mentorName).toSet().toList()..sort();

    final filtered = rooms.where((r) {
      if (_selectedCourse != null && r.courseName != _selectedCourse) {
        return false;
      }
      if (_selectedMentor != null && r.mentorName != _selectedMentor) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      return r.name.toLowerCase().contains(_searchQuery) ||
          r.mentorName.toLowerCase().contains(_searchQuery) ||
          r.courseName.toLowerCase().contains(_searchQuery);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final searchField = TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên phòng, học phần hoặc Mentor...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim().toLowerCase()),
            );
            final courseDropdown = DropdownButtonFormField<String?>(
              initialValue: _selectedCourse,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Học phần',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả')),
                ...courses.map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedCourse = v),
            );
            final mentorDropdown = DropdownButtonFormField<String?>(
              initialValue: _selectedMentor,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Mentor',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả')),
                ...mentors.map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedMentor = v),
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 2, child: searchField),
                  const SizedBox(width: 10),
                  Expanded(child: courseDropdown),
                  const SizedBox(width: 10),
                  Expanded(child: mentorDropdown),
                ],
              );
            }
            return Column(
              children: [
                searchField,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: courseDropdown),
                    const SizedBox(width: 10),
                    Expanded(child: mentorDropdown),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Không tìm thấy phòng học nào.',
              textAlign: TextAlign.center,
            ),
          )
        else
          ...filtered.map((room) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.meeting_room_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  room.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${room.courseName} • Mentor: ${room.mentorName}',
                ),
                trailing: OutlinedButton(
                  onPressed: () => context.push('/rooms/${room.id}'),
                  child: const Text('Mở'),
                ),
                onTap: () => context.push('/rooms/${room.id}'),
              ),
            );
          }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double ratio;
  final Color color;

  const _DonutChartCard({
    required this.title,
    required this.subtitle,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (ratio * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(
                painter: _RingPainter(ratio: ratio, color: color),
                child: Center(
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double ratio;
  final Color color;

  _RingPainter({required this.ratio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 8) / 2;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * ratio.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.ratio != ratio || oldDelegate.color != color;
}
