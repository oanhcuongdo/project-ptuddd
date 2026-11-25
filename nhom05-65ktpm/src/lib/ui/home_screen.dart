import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../data/achievements.dart';
import '../data/active_timer.dart';
import '../data/app_database.dart';
import '../data/export.dart';
import '../data/lessons.dart';
import '../data/recommend.dart';
import '../scoring/feedback.dart';
import '../scoring/phonemes.dart';
import '../scoring/rate.dart';
import '../scoring/weak_sounds.dart';
import 'attempt_detail_screen.dart';
import 'practice_screen.dart';
import 'goal_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.stats;
    return Scaffold(
      appBar: AppBar(
        title: Text(const ['Bài học', 'Tiến độ', 'Cài đặt'][_tab]),
        actions: [
          IconButton(
            tooltip: 'Đổi người học',
            icon: const Icon(Icons.switch_account),
            onPressed: () => state.selectUser(null),
          ),
        ],
      ),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : switch (_tab) {
              0 => _LessonsTab(state.user!, stats),
              1 => _ProgressTab(state.user!, stats),
              _ => const _SettingsTab(),
            },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.record_voice_over), label: 'Luyện tập'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Tiến độ'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final User user;
  final Stats stats;
  const _TodayCard(this.user, this.stats);

  @override
  Widget build(BuildContext context) {
    final goal = user.dailyGoalMinutes * 60;
    final progress = (stats.secondsToday / goal).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              children: [
                Icon(Icons.local_fire_department,
                    size: 40, color: stats.streak > 0 ? Colors.deepOrange : theme.disabledColor),
                Text('${stats.streak} ngày', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chào ${user.name}!', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress, minHeight: 8),
                  const SizedBox(height: 4),
                  Text(progress >= 1
                      ? 'Đã hoàn thành mục tiêu hôm nay 🎉'
                      : 'Hôm nay: ${_minutes(stats.secondsToday)} / ${user.dailyGoalMinutes} phút'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _minutes(int seconds) => (seconds / 60).toStringAsFixed(seconds < 600 ? 1 : 0);

class _LessonsTab extends StatelessWidget {
  final User user;
  final Stats stats;
  const _LessonsTab(this.user, this.stats);

  @override
  Widget build(BuildContext context) {
    final rec = recommendLesson(stats.weakSounds, stats.lessons);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _TodayCard(user, stats),
        if (rec != null)
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: Text('Gợi ý hôm nay: ${rec.lesson.title}'),
              subtitle: Text(rec.reason),
              trailing: FilledButton(
                  onPressed: () => openLesson(context, rec.lesson), child: const Text('Luyện')),
            ),
          ),
        for (final l in lessons)
          Card(
            child: ListTile(
              title: Text(l.title),
              subtitle: _LessonSubtitle(l, stats.lessons[l.id]),
              trailing: _isMastered(l, stats.lessons[l.id])
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.chevron_right),
              onTap: () => openLesson(context, l),
            ),
          ),
      ],
    );
  }
}

bool _isMastered(Lesson l, LessonStat? s) =>
    s != null && masteredCount(l, s.itemBest) == l.items.length;

class _LessonSubtitle extends StatelessWidget {
  final Lesson lesson;
  final LessonStat? stat;
  const _LessonSubtitle(this.lesson, this.stat);

  @override
  Widget build(BuildContext context) {
    final s = stat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lesson.description),
        const SizedBox(height: 6),
        if (s == null)
          Text('Chưa luyện • ${lesson.items.length} mục',
              style: Theme.of(context).textTheme.bodySmall)
        else ...[
          LinearProgressIndicator(value: masteredCount(lesson, s.itemBest) / lesson.items.length),
          const SizedBox(height: 2),
          Text(
              '${masteredCount(lesson, s.itemBest)}/${lesson.items.length} mục thành thạo (≥$masteryScore) '
              '• ${s.attempts} lượt • TB ${s.avgScore.round()}',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// Runs a timed practice session; the practice screen may return another
/// lesson id when the learner follows an improvement suggestion.
Future<void> openLesson(BuildContext context, Lesson l) async {
  final state = context.read<AppState>();
  final nav = Navigator.of(context);
  Lesson? next = l;
  while (next != null) {
    final lesson = next;
    final itemBest = state.stats?.lessons[lesson.id]?.itemBest ?? const <String, int>{};
    final sessionId = await state.db.startSession(state.user!.id, lesson.id);
    final watch = ActiveTimer();
    final result = await nav.push<String>(MaterialPageRoute(
        builder: (_) => PracticeScreen(
            lesson: lesson,
            sessionId: sessionId,
            watch: watch,
            itemBest: itemBest,
            startIndex: firstUnmastered(lesson, itemBest))));
    await state.db.endSession(sessionId, watch.elapsedSeconds());
    await state.refresh(); // cập nhật điểm từng mục trước khi mở bài kế tiếp
    next = result == null ? null : lessonById(result);
  }
}

/// Huy hiệu đã mở (nổi bật) và chưa mở (mờ); nhấn giữ để xem điều kiện.
class _Badges extends StatelessWidget {
  final List<Achievement> items;
  const _Badges(this.items);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = items.where((a) => a.unlocked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Huy hiệu ($done/${items.length})', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final a in items)
            Tooltip(
              message: a.description,
              child: Semantics(
                label: '${a.title}: ${a.unlocked ? 'đã mở' : 'chưa mở'}. ${a.description}',
                excludeSemantics: true,
                child: Chip(
                  avatar: Icon(a.unlocked ? Icons.emoji_events : Icons.lock_outline,
                      size: 18, color: a.unlocked ? Colors.amber.shade700 : theme.disabledColor),
                  label: Text(a.title,
                      style: a.unlocked ? null : TextStyle(color: theme.disabledColor)),
                ),
              ),
            ),
        ]),
      ],
    );
  }
}

const _chartLabelH = 16.0;
const _chartBarH = 110.0;

/// Biểu đồ đường điểm trung bình theo ngày; vạch 50/75 trùng ngưỡng màu của điểm.
class _TrendChart extends StatelessWidget {
  final List<DayScore> trend;
  const _TrendChart(this.trend);

  @override
  Widget build(BuildContext context) {
    final days = trend.where((d) => d.avg != null).toList();
    if (days.length < 2) {
      return const Padding(
          padding: EdgeInsets.all(8), child: Text('Cần luyện ít nhất 2 ngày để vẽ xu hướng.'));
    }
    final theme = Theme.of(context);
    return Semantics(
      label: 'Điểm trung bình theo ngày: '
          '${days.map((d) => '${weekdayLabel(d.date)} ${d.avg!.round()}').join(', ')}',
      child: SizedBox(
        height: 130,
        width: double.infinity,
        child: CustomPaint(
          painter: _TrendPainter([for (final d in trend) d.avg],
              line: theme.colorScheme.primary,
              grid: theme.colorScheme.outlineVariant,
              text: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double?> values;
  final Color line, grid, text;
  _TrendPainter(this.values, {required this.line, required this.grid, required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    const left = 28.0, pad = 8.0;
    final w = size.width - left - pad;
    double x(int i) => left + w * i / (values.length - 1);
    double y(double v) => pad + (size.height - 2 * pad) * (1 - v.clamp(0, 100) / 100);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final g in const [50.0, 75.0, 100.0]) {
      canvas.drawLine(Offset(left, y(g)), Offset(size.width - pad, y(g)), gridPaint);
      final tp = TextPainter(
          text: TextSpan(text: '${g.round()}', style: TextStyle(fontSize: 10, color: text)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(0, y(g) - tp.height / 2));
    }

    final path = Path();
    final dot = Paint()..color = line;
    var started = false;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final p = Offset(x(i), y(v));
      started ? path.lineTo(p.dx, p.dy) : path.moveTo(p.dx, p.dy);
      started = true;
      canvas.drawCircle(p, 3.5, dot);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_TrendPainter old) => true;
}

class _ProgressTab extends StatelessWidget {
  final User user;
  final Stats stats;
  const _ProgressTab(this.user, this.stats);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxSecs = stats.last7Days
        .map((d) => d.seconds)
        .fold(user.dailyGoalMinutes * 60, (a, b) => a > b ? a : b);
    Widget tile(String label, String value, IconData icon) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Icon(icon, color: theme.colorScheme.primary),
                Text(value, style: theme.textTheme.titleLarge),
                Text(label, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ]),
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(children: [
          tile('Chuỗi hiện tại', '${stats.streak}', Icons.local_fire_department),
          tile('Chuỗi dài nhất', '${stats.bestStreak}', Icons.emoji_events),
        ]),
        Row(children: [
          tile('Tổng phút học', _minutes(stats.totalSeconds), Icons.timer),
          tile('Lượt nói', '${stats.attempts}', Icons.mic),
          tile('Điểm TB', stats.avgScore.toStringAsFixed(0), Icons.grade),
        ]),
        Row(children: [
          tile(
              stats.rate == null
                  ? 'Trình độ (cần $minAttemptsForRate lượt nói)'
                  : 'Trình độ · rate ${stats.rate!.value.toStringAsFixed(0)}',
              stats.rate?.level.label ?? '—',
              Icons.leaderboard),
        ]),
        const SizedBox(height: 12),
        _Badges(achievements(
            bestStreak: stats.bestStreak,
            attempts: stats.attempts,
            lessonStats: stats.lessons,
            rate: stats.rate)),
        const SizedBox(height: 12),
        Text('Thời gian học 7 ngày qua (phút, vạch = mục tiêu)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: Stack(children: [
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in stats.last7Days)
                    Expanded(
                      child: Semantics(
                        label: '${weekdayLabel(d.date)} ${d.date}: ${_minutes(d.seconds)} phút',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                                height: _chartLabelH,
                                child: Text(_minutes(d.seconds), style: theme.textTheme.labelSmall)),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              height: _chartBarH * d.seconds / maxSecs,
                              decoration: BoxDecoration(
                                color: d.seconds >= user.dailyGoalMinutes * 60
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withValues(alpha: 0.4),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                            SizedBox(
                                height: _chartLabelH,
                                child: Text('${weekdayLabel(d.date)} ${d.date.substring(8)}',
                                    style: theme.textTheme.labelSmall)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: _chartLabelH + _chartBarH * (user.dailyGoalMinutes * 60) / maxSecs,
              child: Container(height: 1.5, color: theme.colorScheme.tertiary),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Điểm trung bình theo ngày ($trendDays ngày gần nhất)',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _TrendChart(stats.scoreTrend),
        const SizedBox(height: 16),
        Text('Âm hay sai nhất (${stats.attempts < weakWindow ? 'tất cả' : '$weakWindow'} lượt gần đây)',
            style: theme.textTheme.titleMedium),
        if (stats.weakSounds.isEmpty)
          const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Chưa đủ dữ liệu (mỗi âm cần gặp ít nhất 3 lần).')),
        for (final w in stats.weakSounds)
          ListTile(
            dense: true,
            leading: Text('/${ipa(w.phoneme)}/', style: theme.textTheme.titleLarge),
            title: Text('Sai ${(w.rate * 100).round()}% (${w.errors}/${w.seen} lần)'),
            subtitle: LinearProgressIndicator(value: w.rate),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showWeakSound(context, w),
          ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('Lịch sử gần đây', style: theme.textTheme.titleMedium)),
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Sao chép CSV'),
            onPressed: () async {
              final db = context.read<AppState>().db;
              final csv = attemptsToCsv(await db.allAttempts(user.id));
              await Clipboard.setData(ClipboardData(text: csv));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép toàn bộ lịch sử (CSV)')));
              }
            },
          ),
        ]),
        for (final a in stats.recentAttempts)
          ListTile(
            dense: true,
            title: Text(a['expected_text'] as String),
            subtitle: Text('Nghe được: "${a['recognized_text']}"'),
            trailing: Text('${a['score']}', style: theme.textTheme.titleMedium),
            onTap: () async {
              final next = await Navigator.of(context).push<String>(MaterialPageRoute(
                  builder: (_) => AttemptDetailScreen(
                      expected: a['expected_text'] as String,
                      recognized: a['recognized_text'] as String,
                      confidence: (a['confidence'] as num).toDouble(),
                      at: DateTime.parse(a['created_at'] as String))));
              if (next != null && context.mounted) openLesson(context, lessonById(next));
            },
          ),
      ],
    );
  }
}

/// Mẹo phát âm cho một âm hay sai, kèm nút nhảy sang bài luyện tương ứng.
void _showWeakSound(BuildContext context, WeakSound w) {
  final s = suggestionForPhoneme(w.phoneme);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s?.title ?? 'Âm /${ipa(w.phoneme)}/', style: Theme.of(sheet).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Bạn sai ${w.errors}/${w.seen} lần âm này.'),
          const SizedBox(height: 8),
          Text(s?.tip ?? 'Chưa có mẹo riêng cho âm này. Hãy nghe mẫu và nói chậm từng từ.'),
          if (s != null && s.practiceWords.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Cặp từ cần phân biệt: ${s.practiceWords.join(', ')}'),
          ],
          if (s != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(sheet);
                  openLesson(context, lessonById(s.lessonId));
                },
                child: Text('Luyện bài "${lessonById(s.lessonId).title}"'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final u = state.user!;
    return ListView(
      children: [
        GoalSlider(
            minutes: u.dailyGoalMinutes, onCommit: (m) => state.updateSettings(goal: m)),
        SwitchListTile(
          title: const Text('Nhắc nhở luyện tập hằng ngày'),
          value: u.reminderEnabled,
          onChanged: (v) => state.updateSettings(reminder: v),
        ),
        ListTile(
          enabled: u.reminderEnabled,
          title: const Text('Giờ nhắc'),
          trailing: Text(
              '${u.reminderHour.toString().padLeft(2, '0')}:${u.reminderMinute.toString().padLeft(2, '0')}'),
          onTap: () async {
            final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: u.reminderHour, minute: u.reminderMinute));
            if (t != null) await state.updateSettings(hour: t.hour, minute: t.minute);
          },
        ),
      ],
    );
  }
}
