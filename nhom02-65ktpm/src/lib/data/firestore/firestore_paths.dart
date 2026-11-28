import 'package:cloud_firestore/cloud_firestore.dart';

/// Đường dẫn các collection trong Firestore (gom một chỗ để tránh gõ sai).
///
/// ```
/// tips/{tipCode}                         thư viện gợi ý, client chỉ đọc
/// users/{uid}                            hồ sơ + cài đặt
/// users/{uid}/meals/{mealId}             nhật ký
/// users/{uid}/favorites/{favId}          món hay ăn ("Ăn lại")
/// users/{uid}/challenges/{challengeId}   thử thách tuần
/// ```
class FirestorePaths {
  FirestorePaths(this.db);

  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> tips() => db.collection('tips');

  DocumentReference<Map<String, dynamic>> user(String uid) =>
      db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> meals(String uid) =>
      user(uid).collection('meals');

  CollectionReference<Map<String, dynamic>> favorites(String uid) =>
      user(uid).collection('favorites');

  CollectionReference<Map<String, dynamic>> challenges(String uid) =>
      user(uid).collection('challenges');
}
