import 'package:flutter/material.dart';

import '../../../application/confirm_and_save_meal.dart';
import '../../../application/tip_resolver.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/result.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/diary_strings.dart';
import '../../../domain/entities/food_item.dart';
import '../../../domain/entities/meal.dart';
import '../../../domain/entities/nutrition_levels.dart';
import '../../../domain/enums.dart';
import '../../../domain/rules/meal_type_rules.dart';
import '../../../domain/rules/vn_calendar.dart';
import '../../utils/formatters.dart';
import '../../widgets/disclaimer_note.dart';
import 'food_item_card.dart';
import 'review_controller.dart';

/// Màn hình Xác nhận / Sửa bữa ăn.
///
/// Dùng chung cho: nhập thủ công, kết quả quét AI, nhập tên món, gọi món,
/// ăn lại (giữ để sửa) và sửa bữa đã lưu. Chỉ ghi Firestore khi nhấn "Lưu".
class ReviewMealScreen extends StatefulWidget {
  const ReviewMealScreen({
    super.key,
    required this.items,
    required this.inputMethod,
    this.fromAi = false,
    this.existingMeal,
    this.initialEatenAt,
    this.initialMealType,
  });

  final List<FoodItem> items;
  final InputMethod inputMethod;
  final bool fromAi;
  final Meal? existingMeal;
  final DateTime? initialEatenAt;
  final MealType? initialMealType;

  /// Mở màn hình; trả về true nếu đã lưu.
  static Future<bool> open(
    BuildContext context, {
    required List<FoodItem> items,
    required InputMethod inputMethod,
    bool fromAi = false,
    Meal? existingMeal,
    DateTime? initialEatenAt,
    MealType? initialMealType,
    bool replace = false,
  }) async {
    final route = MaterialPageRoute<bool>(
      builder: (_) => ReviewMealScreen(
        items: items,
        inputMethod: inputMethod,
        fromAi: fromAi,
        existingMeal: existingMeal,
        initialEatenAt: initialEatenAt,
        initialMealType: initialMealType,
      ),
    );
    final navigator = Navigator.of(context);
    final saved = replace ? await navigator.pushReplacement(route) : await navigator.push(route);
    return saved ?? false;
  }

  /// Nhập thủ công: một món trống, chọn mức độ bằng chip.
  /// [vnDate]: ngày trong nhật ký (null = hôm nay).
  static Future<bool> openManual(
    BuildContext context, {
    DateTime? vnDate,
    MealType? mealType,
    String name = '',
    InputMethod inputMethod = InputMethod.manual,
    bool replace = false,
  }) {
    DateTime? eatenAt;
    final today = VnCalendar.vnDateOf(DateTime.now());
    if (vnDate != null && vnDate != today) {
      final t = MealTypeRules.typicalTime(mealType ?? MealType.lunch);
      eatenAt = VnCalendar.combineVn(vnDate, t.hour, t.minute);
    }
    return open(
      context,
      items: [FoodItem(name: name, category: FoodCategory.mainDish, levels: const NutritionLevels())],
      inputMethod: inputMethod,
      initialEatenAt: eatenAt,
      initialMealType: mealType,
      replace: replace,
    );
  }

  /// Sửa một bữa đã lưu.
  static Future<bool> openExisting(BuildContext context, Meal meal) => open(
        context,
        items: meal.items,
        inputMethod: meal.inputMethod,
        fromAi: meal.inputMethod == InputMethod.photo || meal.inputMethod == InputMethod.menu,
        existingMeal: meal,
      );

  @override
  State<ReviewMealScreen> createState() => _ReviewMealScreenState();
}

class _ReviewMealScreenState extends State<ReviewMealScreen> {
  late final ReviewController _controller;

  @override
  void initState() {
    super.initState();
    final tips = sl<TipResolver>();
    _controller = ReviewController(
      items: widget.items,
      inputMethod: widget.inputMethod,
      fromAi: widget.fromAi,
      tips: tips,
      save: sl<ConfirmAndSaveMeal>(),
      existingMeal: widget.existingMeal,
      initialEatenAt: widget.initialEatenAt,
      initialMealType: widget.initialMealType,
    );
    // Món thủ công: gắn gợi ý theo quy tắc khi thư viện tips sẵn sàng.
    if (!widget.fromAi && widget.existingMeal == null) {
      tips.ensureLoaded().then((_) {
        if (mounted) _controller.refreshManualTips();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final vnNow = VnCalendar.toVnWallClock(DateTime.now());
    final current = VnCalendar.toVnWallClock(_controller.eatenAt);
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(vnNow.year - 1),
      lastDate: DateTime(vnNow.year, vnNow.month, vnNow.day),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;
    _controller.setEatenAt(VnCalendar.combineVn(
      DateTime.utc(date.year, date.month, date.day),
      time.hour,
      time.minute,
    ));
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    switch (_controller.save()) {
      case Ok():
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text(ReviewStrings.saved)));
        Navigator.of(context).pop(true);
      case Err(:final failure):
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(ReviewStrings.discardTitle),
        content: const Text(ReviewStrings.discardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(ReviewStrings.keepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(ReviewStrings.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return PopScope(
          canPop: !_controller.dirty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmDiscard();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(_controller.isEditingExisting
                  ? ReviewStrings.titleEdit
                  : ReviewStrings.titleNew),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _buildMealInfo(context),
                const SizedBox(height: 12),
                for (final entry in _controller.entries)
                  FoodItemCard(key: entry.key, entry: entry, controller: _controller),
                OutlinedButton.icon(
                  onPressed: _controller.entries.length >= 10 ? null : _controller.addBlankItem,
                  icon: const Icon(Icons.add),
                  label: const Text(ReviewStrings.addItem),
                ),
                const SizedBox(height: 16),
                const DisclaimerNote(full: true),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text(AppStrings.save),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealInfo(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ReviewStrings.mealType, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (final type in MealType.values)
                  ChoiceChip(
                    label: Text(AppStrings.mealType(type)),
                    selected: _controller.mealType == type,
                    onSelected: (_) => _controller.setMealType(type),
                  ),
              ],
            ),
            const Divider(height: 24),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 20),
                    const SizedBox(width: 8),
                    Text('${ReviewStrings.time}: ', style: theme.textTheme.labelLarge),
                    Text(Formatters.dateTime(_controller.eatenAt)),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_outlined, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
