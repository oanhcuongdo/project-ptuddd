import 'package:flutter/material.dart';

import '../../../application/meal_trash_actions.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/diary_strings.dart';
import '../../../domain/entities/meal.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/meal_card.dart';

/// Thùng rác: khôi phục hoặc xóa vĩnh viễn các bữa đã xóa mềm.
class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  Future<bool> _confirm(BuildContext context, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(TrashStrings.confirmDeleteTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(TrashStrings.deleteForever),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final trash = sl<MealTrashActions>();
    return StreamBuilder<List<Meal>>(
      stream: trash.watchTrash(),
      builder: (context, snapshot) {
        final meals = snapshot.data ?? const <Meal>[];
        return Scaffold(
          appBar: AppBar(
            title: const Text(TrashStrings.title),
            actions: [
              if (meals.isNotEmpty)
                IconButton(
                  tooltip: TrashStrings.emptyTrash,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () async {
                    if (await _confirm(context, TrashStrings.confirmEmptyMessage)) {
                      trash.emptyTrash(meals);
                      if (context.mounted) _toast(context, TrashStrings.deleted);
                    }
                  },
                ),
            ],
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : meals.isEmpty
                  ? const EmptyState(icon: Icons.delete_outline, title: TrashStrings.empty)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: meals.length,
                      itemBuilder: (context, index) {
                        final meal = meals[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MealCard(meal: meal, showDate: true),
                            Row(
                              children: [
                                if (meal.deletedAt != null)
                                  Expanded(
                                    child: Text(
                                      TrashStrings.deletedAt(Formatters.dateTime(meal.deletedAt!)),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  )
                                else
                                  const Spacer(),
                                TextButton.icon(
                                  onPressed: () {
                                    trash.restore(meal.id!);
                                    _toast(context, TrashStrings.restored);
                                  },
                                  icon: const Icon(Icons.restore),
                                  label: const Text(TrashStrings.restore),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    if (await _confirm(context, TrashStrings.confirmDeleteMessage)) {
                                      trash.deleteForever(meal.id!);
                                      if (context.mounted) _toast(context, TrashStrings.deleted);
                                    }
                                  },
                                  icon: const Icon(Icons.delete_forever_outlined),
                                  label: const Text(TrashStrings.deleteForever),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                          ],
                        );
                      },
                    ),
        );
      },
    );
  }
}
