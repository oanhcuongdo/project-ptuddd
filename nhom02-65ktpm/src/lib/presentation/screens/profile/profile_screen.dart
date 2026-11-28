import 'package:flutter/material.dart';

import '../../../application/session_service.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/auth_strings.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/enums.dart';
import '../../widgets/goal_option_tile.dart';
import '../../widgets/reminder_times_editor.dart';

/// Hồ sơ: mục tiêu, giờ nhắc, giao diện, đăng xuất, miễn trừ trách nhiệm.
/// Mọi thay đổi được lưu ngay vào Firestore (users/{uid}).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<SessionService>();
    return Scaffold(
      appBar: AppBar(title: const Text(ProfileStrings.title)),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final profile = session.profile;
          if (profile == null) return const Center(child: CircularProgressIndicator());
          return _ProfileBody(session: session, profile: profile);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.session, required this.profile});

  final SessionService session;
  final UserProfile profile;

  void _save(UserProfile updated) => session.saveProfile(updated);

  Future<void> _pickGoal(BuildContext context) async {
    final goal = await showModalBottomSheet<Goal>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ProfileStrings.chooseGoal, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final g in Goal.values)
                GoalOptionTile(
                  goal: g,
                  selected: g == profile.goal,
                  onTap: () => Navigator.pop(context, g),
                ),
            ],
          ),
        ),
      ),
    );
    if (goal != null && goal != profile.goal) _save(profile.copyWith(goal: goal));
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(ProfileStrings.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(ProfileStrings.signOut),
          ),
        ],
      ),
    );
    if (ok == true) await session.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = session.user?.email ?? '';
    final initial = profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : '?';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(initial, style: theme.textTheme.titleLarge),
            ),
            title: Text(profile.displayName, style: theme.textTheme.titleMedium),
            subtitle: Text(email),
          ),
        ),
        const SizedBox(height: 16),
        _SectionTitle(ProfileStrings.goalSection),
        Card(
          child: ListTile(
            leading: Icon(GoalOptionTile.iconOf(profile.goal), color: theme.colorScheme.primary),
            title: Text(AppStrings.goal(profile.goal)),
            subtitle: Text(AppStrings.goalDescription(profile.goal)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickGoal(context),
          ),
        ),
        const SizedBox(height: 16),
        _SectionTitle(ProfileStrings.reminderSection),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(ProfileStrings.reminderEnabled),
                  value: profile.reminders.enabled,
                  onChanged: (v) =>
                      _save(profile.copyWith(reminders: profile.reminders.copyWith(enabled: v))),
                ),
                ReminderTimesEditor(
                  times: profile.reminders.times,
                  enabled: profile.reminders.enabled,
                  onChanged: (times) => _save(
                    profile.copyWith(reminders: profile.reminders.copyWith(times: times)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionTitle(ProfileStrings.themeSection),
        SegmentedButton<AppThemeMode>(
          segments: [
            for (final mode in AppThemeMode.values)
              ButtonSegment(value: mode, label: Text(AppStrings.themeMode(mode))),
          ],
          selected: {profile.themeMode},
          onSelectionChanged: (value) => _save(profile.copyWith(themeMode: value.first)),
        ),
        const SizedBox(height: 16),
        _SectionTitle(ProfileStrings.baselineSection),
        Card(
          child: ListTile(
            leading: const Icon(Icons.history_edu_outlined),
            title: Text(ProfileStrings.baselineSummary(
              profile.baseline.sugaryDrinksPerWeek,
              profile.baseline.eatOutPerWeek,
            )),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _confirmSignOut(context),
          icon: const Icon(Icons.logout),
          label: const Text(ProfileStrings.signOut),
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.disclaimerFull,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
