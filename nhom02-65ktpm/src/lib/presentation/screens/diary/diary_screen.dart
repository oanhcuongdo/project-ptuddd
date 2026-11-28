import 'package:flutter/material.dart';

import '../../../application/meal_queries.dart';
import '../../../application/meal_trash_actions.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/diary_strings.dart';
import '../../../core/theme/level_colors.dart';
import '../../../domain/entities/meal.dart';
import '../../../domain/enums.dart';
import '../../../domain/rules/vn_calendar.dart';
import '../../utils/formatters.dart';
import '../../widgets/meal_card.dart';
import '../review/review_meal_screen.dart';
import '../trash/trash_screen.dart';

/// Nhật ký ăn uống theo ngày, nhóm theo 4 bữa.
/// Vuốt sang trái để xóa (xóa mềm) kèm SnackBar "Hoàn tác".
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _queries = sl<MealQueries>();
  final _trash = sl<MealTrashActions>();

  late DateTime _day = VnCalendar.vnDateOf(DateTime.now());
  late Stream<List<Meal>> _stream = _queries.watchDay(_day);

  /// Bữa vừa vuốt xóa: ẩn ngay để Dismissible không còn trong cây widget
  /// trong lúc chờ stream Firestore cập nhật.
  final Set<String> _hidden = {};

  DateTime get _today => VnCalendar.vnDateOf(DateTime.now());

  void _setDay(DateTime day) {
    if (day.isAfter(_today)) return;
    setState(() {
      _day = day;
      _stream = _queries.watchDay(day);
    });
  }

  Future<void> _pickDay() async {
    final today = _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_day.year, _day.month, _day.day),
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked != null) _setDay(DateTime.utc(picked.year, picked.month, picked.day));
  }

  void _delete(Meal meal) {
    final id = meal.id!;
    setState(() => _hidden.add(id));
    _trash.moveToTrash(id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text(DiaryStrings.movedToTrash),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () {
            _trash.restore(id);
            if (mounted) setState(() => _hidden.remove(id));
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(DiaryStrings.title),
        actions: [
          IconButton(
            tooltip: DiaryStrings.trash,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const TrashScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          _DaySelector(
            label: Formatters.dayLabel(_day),
            canGoNext: _day.isBefore(_today),
            onPrevious: () => _setDay(_day.subtract(const Duration(days: 1))),
            onNext: () => _setDay(_day.add(const Duration(days: 1))),
            onPick: _pickDay,
          ),
          Expanded(
            child: StreamBuilder<List<Meal>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(DiaryStrings.loadError));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildSections(
                  snapshot.data!.where((m) => !_hidden.contains(m.id)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSections(List<Meal> meals) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        for (final type in MealType.values) ...[
          _SectionHeader(
            type: type,
            count: meals.where((m) => m.mealType == type).length,
            onAdd: () => ReviewMealScreen.openManual(context, vnDate: _day, mealType: type),
          ),
          ..._mealsOf(meals, type),
        ],
      ],
    );
  }

  List<Widget> _mealsOf(List<Meal> meals, MealType type) {
    final ofType = meals.where((m) => m.mealType == type).toList()
      ..sort((a, b) => a.eatenAt.compareTo(b.eatenAt));
    if (ofType.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            DiaryStrings.emptyDay,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ];
    }
    final caution = LevelColors.colorsOf(LevelTone.caution, Theme.of(context).brightness);
    return [
      for (final meal in ofType)
        Dismissible(
          key: ValueKey(meal.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: caution.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.delete_outline, color: caution.foreground),
          ),
          onDismissed: (_) => _delete(meal),
          child: MealCard(
            meal: meal,
            onTap: () => ReviewMealScreen.openExisting(context, meal),
          ),
        ),
    ];
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.label,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final String label;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: DiaryStrings.previousDay,
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          IconButton(
            tooltip: DiaryStrings.nextDay,
            icon: const Icon(Icons.chevron_right),
            onPressed: canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.type, required this.count, required this.onAdd});

  final MealType type;
  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Icon(MealCard.mealTypeIcon(type), size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            AppStrings.mealType(type),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Text(DiaryStrings.itemCount(count), style: theme.textTheme.bodySmall),
          ],
          const Spacer(),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(DiaryStrings.addToMeal),
          ),
        ],
      ),
    );
  }
}
