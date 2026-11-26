import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/contracts/contracts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass.dart';

/// Menu dành cho nhóm phát triển (chỉ hiện ở bản debug, nút 🛠 trên trang chủ).
///
/// - Đăng nhập nhanh tài khoản demo do `seed_dev.py` tạo.
/// - Tạo / xoá dữ liệu học giả để dựng trang chủ, thống kê, huy hiệu.
/// - Xem hợp đồng nào đang chạy bản giả, hợp đồng nào đã có bản thật.
class DevMenuScreen extends ConsumerStatefulWidget {
  const DevMenuScreen({super.key});

  @override
  ConsumerState<DevMenuScreen> createState() => _DevMenuScreenState();
}

class _DevMenuScreenState extends ConsumerState<DevMenuScreen> {
  bool _busy = false;

  Future<void> _run(String done, Future<void> Function() action) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login(String email) => _run('Đã đăng nhập $email', () async {
    await ref.read(authRepositoryProvider).login(email, 'Demo12345');
    ref.invalidate(currentUserProvider);
    final progress = ref.read(progressServiceProvider);
    await ref.read(outboxProvider).flush();
    await progress.pullFromServer();
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final events = ref.watch(learningEventsProvider).value ?? const <LearningEvent>[];
    final summary = ProgressSummary.from(events);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );

    return GlassScaffold(
      appBar: const GlassAppBar(title: Text('Menu dev')),
      body: AbsorbPointer(
        absorbing: _busy,
        // Builder: lấy MediaQuery bên trong Scaffold (đã cộng chiều cao thanh tiêu đề).
        child: Builder(
          builder: (context) {
            final pad = MediaQuery.paddingOf(context);
            return ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.fromLTRB(16, pad.top + 12, 16, pad.bottom + 24),
              children: [
                section('Tài khoản', [
                  user.when(
                    data: (u) => Text(
                      u == null ? 'Chưa đăng nhập' : '${u.shownName} · ${u.email} · ${u.xpTotal} XP',
                      key: const Key('dev-user'),
                    ),
                    loading: () => const Text('Đang kiểm tra...'),
                    error: (e, _) => Text('Không gọi được server: $e', style: muted),
                  ),
                  const SizedBox(height: 4),
                  Text('Cần server chạy + `python -m scripts.seed_dev`. Mật khẩu: Demo12345', style: muted),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GlassButton(
                        label: 'demo@ (có tiến độ)',
                        prominent: true,
                        onPressed: () => _login('demo@chailish.dev'),
                      ),
                      GlassButton(label: 'new@ (mới tinh)', onPressed: () => _login('new@chailish.dev')),
                      GlassButton(
                        label: 'Đăng xuất',
                        onPressed: () => _run('Đã đăng xuất', () async {
                          await ref.read(authRepositoryProvider).logout();
                          ref.invalidate(currentUserProvider);
                        }),
                      ),
                    ],
                  ),
                ]),
                section('Dữ liệu học tập trên máy', [
                  Text(
                    '${events.length} sự kiện · ${summary.xpTotal} XP · streak ${summary.currentStreak} ngày '
                    '(dài nhất ${summary.longestStreak}) · hôm nay ${summary.minutesOn(DateTime.now())} phút',
                    key: const Key('dev-progress'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GlassButton(
                        key: const Key('dev-generate'),
                        label: 'Tạo 30 ngày học giả',
                        icon: Icons.auto_awesome,
                        onPressed: () => _run('Đã tạo dữ liệu giả (chỉ trên máy)', () async {
                          final lessons = await ref.read(lessonRepositoryProvider).lessons();
                          await ref.read(progressServiceProvider).addAll(generateDemoEvents(lessons));
                        }),
                      ),
                      GlassButton(
                        label: 'Kéo từ server',
                        icon: Icons.cloud_download_outlined,
                        onPressed: () => _run('Đã kéo sự kiện từ server', () async {
                          await ref.read(progressServiceProvider).pullFromServer();
                        }),
                      ),
                      GlassButton(
                        label: 'Ghi 1 sự kiện thử',
                        icon: Icons.add,
                        onPressed: () => _run('Đã ghi (và gửi nếu đã đăng nhập)', () async {
                          await ref
                              .read(progressServiceProvider)
                              .record(
                                LearningEvent(
                                  type: LearningEventType.studySession,
                                  xp: 1,
                                  durationSec: 60,
                                  refId: 'dev-menu',
                                ),
                              );
                        }),
                      ),
                      GlassButton(
                        label: 'Xoá trên máy',
                        icon: Icons.delete_outline,
                        onPressed: () => _run('Đã xoá sự kiện trên máy', () async {
                          ref.read(progressServiceProvider).clearLocal();
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<int>(
                    stream: ref.watch(outboxProvider).pendingChanges,
                    builder: (context, snap) => Text('Outbox đang chờ gửi: ${snap.data ?? 0}', style: muted),
                  ),
                ]),
                section('Hợp đồng giữa các tính năng', [
                  Text(
                    AppConfig.fakeData
                        ? 'Đang ép dùng bản giả (FAKE_DATA=true)'
                        : 'Bản giả = chủ sở hữu chưa làm bản thật',
                    style: muted,
                  ),
                  const SizedBox(height: 8),
                  for (final c in contractEntries)
                    _ContractRow(entry: c, isFake: ref.watch(c.provider) is FakeImplementation),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ContractRow extends StatelessWidget {
  final ContractEntry entry;
  final bool isFake;

  const _ContractRow({required this.entry, required this.isFake});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isFake ? AppColors.warningOrange : AppColors.jadeGreen;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: ShapeDecoration(color: color.withValues(alpha: 0.25), shape: const StadiumBorder()),
            child: Text(isFake ? 'GIẢ' : 'THẬT', style: theme.textTheme.labelSmall),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(entry.name)),
          Text('${entry.owner} ${entry.issues}', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
