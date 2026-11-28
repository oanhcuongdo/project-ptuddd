import '../domain/entities/meal.dart';
import '../domain/repositories/meal_repository.dart';
import 'meal_events.dart';
import 'session_service.dart';

/// Xóa mềm / khôi phục / xóa vĩnh viễn bữa ăn.
class MealTrashActions {
  MealTrashActions(this._meals, this._session, this._events);

  final MealRepository _meals;
  final SessionService _session;
  final MealEvents _events;

  Stream<List<Meal>> watchTrash() => _meals.watchDeletedMeals(_session.uid);

  /// Xóa mềm: chuyển vào Thùng rác (có thể Hoàn tác).
  void moveToTrash(String mealId) {
    _meals.softDelete(_session.uid, mealId);
    _events.notifyChanged();
  }

  void restore(String mealId) {
    _meals.restore(_session.uid, mealId);
    _events.notifyChanged();
  }

  /// Xóa thật document khỏi Firestore (không khôi phục được).
  void deleteForever(String mealId) {
    _meals.deletePermanently(_session.uid, mealId);
    _events.notifyChanged();
  }

  void emptyTrash(List<Meal> meals) {
    for (final meal in meals) {
      if (meal.id != null) _meals.deletePermanently(_session.uid, meal.id!);
    }
    _events.notifyChanged();
  }
}
