import '../entities/challenge.dart';

abstract class ChallengeRepository {
  /// Toàn bộ thử thách, tuần mới nhất trước.
  Stream<List<Challenge>> watchChallenges(String uid);

  Future<List<Challenge>> getChallenges(String uid);

  /// Tạo mới (id null) hoặc cập nhật thử thách. Trả về id.
  String saveChallenge(String uid, Challenge challenge);
}
