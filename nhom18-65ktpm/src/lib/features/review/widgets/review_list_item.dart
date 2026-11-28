import 'package:flutter/material.dart';
import '../../../models/review.dart';

/// Widget hiển thị 1 bình luận / đánh giá (UC-04 & UC-08).
class ReviewListItem extends StatelessWidget {
  const ReviewListItem({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final rawName = review.riderName?.trim() ?? '';
    final displayName = rawName.isNotEmpty ? rawName : 'Khách hàng';
    final initial = rawName.isNotEmpty ? rawName.substring(0, 1).toUpperCase() : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE3F2FD),
                child: initial != null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1565C0),
                        ),
                      )
                    : const Icon(Icons.person, size: 17, color: Color(0xFF1565C0)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 17,
                    color: Colors.amber[700],
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Text(
                review.comment!,
                style: TextStyle(color: Colors.grey[800], fontSize: 13.5, height: 1.35),
              ),
            ),
          ],
          if (review.createdAt != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Text(
                _formatDate(review.createdAt!),
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
