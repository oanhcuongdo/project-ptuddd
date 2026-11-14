import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../data/app_database.dart';
import '../data/lessons.dart';
import '../scoring/phonemes.dart';
import 'practice_screen.dart';

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
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _TodayCard(user, stats),
        for (final l in lessons)
          Card(
            child: ListTile(
              title: Text(l.title),
              subtitle: Text(l.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openLesson(context, l),
            ),
          ),
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
    final sessionId = await state.db.startSession(state.user!.id, lesson.id);
    final watch = Stopwatch()..start();
    final result = await nav.push<String>(MaterialPageRoute(
        builder: (_) => PracticeScreen(lesson: lesson, sessionId: sessionId, watch: watch)));
    await state.db.endSession(sessionId, watch.elapsed.inSeconds);
    next = result == null ? null : lessonById(result);
  }
  await state.refresh();
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
        const SizedBox(height: 12),
        Text('Thời gian học 7 ngày qua (phút)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in stats.last7Days)
                Expanded(
                  child: Semantics(
                    label: '${d.date}: ${_minutes(d.seconds)} phút',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(_minutes(d.seconds), style: theme.textTheme.labelSmall),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          height: 110 * d.seconds / maxSecs,
                          decoration: BoxDecoration(
                            color: d.seconds >= user.dailyGoalMinutes * 60
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        Text(d.date.substring(8), style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Âm hay sai nhất', style: theme.textTheme.titleMedium),
        if (stats.topErrors.isEmpty)
          const Padding(padding: EdgeInsets.all(8), child: Text('Chưa có dữ liệu.')),
        for (final e in stats.topErrors.entries)
          ListTile(
            dense: true,
            leading: Text('/${ipa(e.key)}/', style: theme.textTheme.titleLarge),
            title: Text('${e.value} lần'),
          ),
        const SizedBox(height: 8),
        Text('Lịch sử gần đây', style: theme.textTheme.titleMedium),
        for (final a in stats.recentAttempts)
          ListTile(
            dense: true,
            title: Text(a['expected_text'] as String),
            subtitle: Text('Nghe được: "${a['recognized_text']}"'),
            trailing: Text('${a['score']}', style: theme.textTheme.titleMedium),
          ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final u = state.user!;
    return ListView(
      children: [
        ListTile(
          title: const Text('Mục tiêu hằng ngày'),
          subtitle: Text('${u.dailyGoalMinutes} phút'),
        ),
        Slider(
          value: u.dailyGoalMinutes.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          label: '${u.dailyGoalMinutes} phút',
          onChanged: (v) => state.updateSettings(goal: v.round()),
        ),
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
