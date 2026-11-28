import '../models/challenge_model.dart';

abstract class IChallengeRepository {
  Future<List<ChallengeModel>> getChallenges();
  Future<ChallengeModel?> getChallengeById(String id);
  Future<int> addChallenge(ChallengeModel challenge);
}
