import '../models/proof_model.dart';

abstract class IProofRepository {
  Future<List<ProofModel>> getProofs();
  Future<List<ProofModel>> getPendingProofs();
  Future<int> submitProof(ProofModel proof);
  Future<bool> approveProof(String proofId, {String? feedback});
  Future<bool> rejectProof(String proofId, {required String reason});
}
