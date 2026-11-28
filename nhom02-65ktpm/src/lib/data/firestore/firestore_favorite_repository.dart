import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/favorite_food.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/favorite_repository.dart';
import 'firestore_converters.dart';
import 'firestore_paths.dart';

/// Món hay ăn `users/{uid}/favorites/{favId}` phục vụ "Ăn lại".
class FirestoreFavoriteRepository implements FavoriteRepository {
  FirestoreFavoriteRepository(this._paths);

  final FirestorePaths _paths;

  @override
  Stream<List<FavoriteFood>> watchFavorites(String uid, {int limit = 20}) {
    return _paths
        .favorites(uid)
        .orderBy('last_used_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _fromMap(d.id, d.data())).toList());
  }

  @override
  void recordUse(String uid, FoodItem item) {
    final id = FavoriteFood.buildId(item.name, item.category);
    // merge + increment: lần đầu tạo document với use_count = 1,
    // các lần sau cộng dồn mà không cần đọc trước.
    FirestoreConverters.fireAndForget(
      _paths.favorites(uid).doc(id).set({
        'name': item.name,
        'category': item.category.value,
        'levels': FirestoreConverters.levelsToMap(item.levels),
        'use_count': FieldValue.increment(1),
        'last_used_at': Timestamp.now(),
      }, SetOptions(merge: true)),
      'recordFavorite',
    );
  }

  FavoriteFood _fromMap(String id, Map<String, dynamic> m) => FavoriteFood(
        id: id,
        name: (m['name'] as String?) ?? '',
        category: parseWire(FoodCategory.values, m['category'], FoodCategory.mainDish),
        levels: FirestoreConverters.levelsFromMap(m['levels']),
        useCount: FirestoreConverters.toInt(m['use_count']),
        lastUsedAt: FirestoreConverters.toDateTime(m['last_used_at']),
      );
}
