import 'package:flutter/material.dart';

import '../../../application/reminder_scheduler.dart';
import '../../../application/session_service.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/auth_strings.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/enums.dart';
import '../../widgets/goal_option_tile.dart';
import '../../widgets/reminder_times_editor.dart';

/// Onboarding 4 bước: xác nhận >= 18 tuổi, mục tiêu, thói quen ban đầu, giờ nhắc.
/// Chưa xác nhận đủ 18 tuổi thì không thể vào ứng dụng.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _stepCount = 4;

  final _session = sl<SessionService>();
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  final _birthYearCtrl = TextEditingController();

  int _step = 0;
  bool _ageChecked = false;
  String? _ageError;
  Goal _goal = Goal.balanced;
  int _sugaryDrinks = 3;
  int _eatOut = 5;
  bool _remindersEnabled = true;
  List<String> _times = List.of(AppConfig.defaultReminderTimes);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = _session.user;
    _nameCtrl.text = user?.displayName ?? user?.email?.split('@').first ?? '';
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _birthYearCtrl.dispose();
    super.dispose();
  }

  /// Kiểm tra bước 1: có tên, năm sinh hợp lệ, đủ 18 tuổi và đã tick xác nhận.
  bool _validateAgeStep() {
    final year = int.tryParse(_birthYearCtrl.text.trim());
    final currentYear = DateTime.now().year;
    String? error;
    if (_nameCtrl.text.trim().isEmpty) {
      error = AuthStrings.nameRequired;
    } else if (year == null || year < 1900 || year > currentYear) {
      error = AuthStrings.birthYearInvalid;
    } else if (currentYear - year < AppConfig.minAge || !_ageChecked) {
      error = AuthStrings.ageRestricted;
    }
    setState(() => _ageError = error);
    return error == null;
  }

  void _next() {
    if (_step == 0 && !_validateAgeStep()) return;
    if (_step == _stepCount - 1) {
      _finish();
      return;
    }
    setState(() => _step++);
    _pageCtrl.animateToPage(_step,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageCtrl.animateToPage(_step,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    if (_remindersEnabled && _times.isNotEmpty) {
      // Xin quyền thông báo SAU khi đã giải thích ở bước này.
      await sl<ReminderScheduler>().requestPermission();
    }
    await _session.saveProfile(UserProfile(
      uid: _session.uid,
      displayName: _nameCtrl.text.trim(),
      birthYear: int.tryParse(_birthYearCtrl.text.trim()),
      ageConfirmed: true,
      goal: _goal,
      baseline: BaselineHabits(sugaryDrinksPerWeek: _sugaryDrinks, eatOutPerWeek: _eatOut),
      reminders: ReminderSettings(enabled: _remindersEnabled, times: _times),
    ));
    // AuthGate tự chuyển sang màn hình chính khi hồ sơ được lưu.
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _step > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back)
            : null,
        title: Text('${_step + 1}/$_stepCount'),
        actions: [
          TextButton(onPressed: _session.signOut, child: const Text(ProfileStrings.signOut)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_step + 1) / _stepCount),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildAgeStep(),
                  _buildGoalStep(),
                  _buildBaselineStep(),
                  _buildReminderStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _next,
                  child: _saving
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_step == _stepCount - 1 ? AuthStrings.finish : AppStrings.next),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepScaffold({required String title, String? hint, required List<Widget> children}) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(hint, style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
        ],
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }

  Widget _buildAgeStep() {
    return _stepScaffold(
      title: AuthStrings.onboardingAgeTitle,
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: AuthStrings.displayName,
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _birthYearCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: AuthStrings.birthYear,
            prefixIcon: Icon(Icons.cake_outlined),
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _ageChecked,
          onChanged: (v) => setState(() => _ageChecked = v ?? false),
          title: const Text(AuthStrings.ageConfirm),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        if (_ageError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _ageError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _buildGoalStep() {
    return _stepScaffold(
      title: AuthStrings.onboardingGoalTitle,
      hint: AuthStrings.onboardingGoalHint,
      children: [
        for (final goal in Goal.values)
          GoalOptionTile(
            goal: goal,
            selected: goal == _goal,
            onTap: () => setState(() => _goal = goal),
          ),
      ],
    );
  }

  Widget _buildBaselineStep() {
    return _stepScaffold(
      title: AuthStrings.onboardingBaselineTitle,
      hint: AuthStrings.onboardingBaselineHint,
      children: [
        _CounterRow(
          label: AuthStrings.sugaryDrinksPerWeek,
          value: _sugaryDrinks,
          max: 30,
          onChanged: (v) => setState(() => _sugaryDrinks = v),
        ),
        const SizedBox(height: 12),
        _CounterRow(
          label: AuthStrings.eatOutPerWeek,
          value: _eatOut,
          max: 21,
          onChanged: (v) => setState(() => _eatOut = v),
        ),
      ],
    );
  }

  Widget _buildReminderStep() {
    return _stepScaffold(
      title: AuthStrings.onboardingReminderTitle,
      hint: AuthStrings.onboardingReminderHint,
      children: [
        SwitchListTile(
          value: _remindersEnabled,
          onChanged: (v) => setState(() => _remindersEnabled = v),
          title: const Text(ProfileStrings.reminderEnabled),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        ReminderTimesEditor(
          times: _times,
          enabled: _remindersEnabled,
          onChanged: (v) => setState(() => _times = v),
        ),
      ],
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            IconButton.outlined(
              icon: const Icon(Icons.remove),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton.outlined(
              icon: const Icon(Icons.add),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}
