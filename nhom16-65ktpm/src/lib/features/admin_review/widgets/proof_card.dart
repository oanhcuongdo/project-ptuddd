import 'package:flutter/material.dart';

import '../../../data/models/proof_model.dart';

// Một thẻ minh chứng trong danh sách chờ duyệt.
// Giai đoạn 3 – C1: thẻ nhận ProofModel (dữ liệu thật từ SQLite)
// thay cho MockProof của giai đoạn 2.
class ProofCard extends StatelessWidget {
  const ProofCard({
    super.key,
    required this.proof,
    required this.timeText,
    required this.onTap,
  });

  final ProofModel proof;
  final String timeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(proof.memberName.isNotEmpty ? proof.memberName[0] : '?'),
        ),
        title: Text(proof.challengeTitle),
        subtitle: Text('${proof.memberName} • $timeText'),
        onTap: onTap,
      ),
    );
  }
}
