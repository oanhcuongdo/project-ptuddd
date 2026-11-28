import 'package:flutter/material.dart';

import '../../../application/meal_queries.dart';
import '../../../application/meal_trash_actions.dart';
import '../../../application/relog_meal.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/result.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/diary_strings.dart';
import '../../../domain/entities/favorite_food.dart';
import '../../../domain/enums.dart';
import '../../widgets/empty_state.dart';
import '../review/review_meal_screen.dart';

/// "Ăn lại": danh sách món hay ăn, chạm 1 lần để ghi lại ngay.
class RelogScreen extends StatefulWidget {
  const RelogScreen({super.key});

  static IconData categoryIcon(FoodCategory category) => switch (category) {
        FoodCategory.drink => Icons.local_cafe_outlined,
        FoodCategory.mainDish => Icons.ramen_dining_outlined,
        FoodCategory.snack => Icons.cookie_outlined,
        FoodCategory.dessert => Icons.icecream_outlined,
      };

  @override
  State<RelogScreen> createState() => _RelogScreenState();
}

class _RelogScreenState extends State<RelogScreen> {
  final _relog = sl<RelogMeal>();
  final _trash = sl<MealTrashActions>();
  late final Stream<List<FavoriteFood>> _stream = sl<MealQueries>().watchFavorites();
  bool _byFrequency = false;

  void _logNow(FavoriteFood favorite) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    switch (_relog(favorite)) {
      case Ok(:final value):
        messenger.showSnackBar(SnackBar(
          content: Text(RelogStrings.logged(favorite.name)),
          action: SnackBarAction(
            label: AppStrings.undo,
            // Hoàn tác: bữa vừa tạo chưa từng hiển thị, xóa hẳn là hợp lý.
            onPressed: () => _trash.deleteForever(value),
          ),
        ));
      case Err(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  void _editBeforeSave(FavoriteFood favorite) {
    ReviewMealScreen.open(
      context,
      items: [_relog.toItem(favorite)],
      inputMethod: InputMethod.relog,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(RelogStrings.title)),
      body: StreamBuilder<List<FavoriteFood>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final favorites = List.of(snapshot.data!);
          if (favorites.isEmpty) {
            return const EmptyState(icon: Icons.replay, title: RelogStrings.empty);
          }
          if (_byFrequency) {
            favorites.sort((a, b) => b.useCount.compareTo(a.useCount));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text(RelogStrings.recent)),
                  ButtonSegment(value: true, label: Text(RelogStrings.frequent)),
                ],
                selected: {_byFrequency},
                onSelectionChanged: (v) => setState(() => _byFrequency = v.first),
              ),
              const SizedBox(height: 8),
              Text(RelogStrings.tapHint, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              for (final favorite in favorites)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(RelogScreen.categoryIcon(favorite.category))),
                    title: Text(favorite.name),
                    subtitle: Text(
                      '${AppStrings.category(favorite.category)} • '
                      '${RelogStrings.useCount(favorite.useCount)}',
                    ),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => _logNow(favorite),
                    onLongPress: () => _editBeforeSave(favorite),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
