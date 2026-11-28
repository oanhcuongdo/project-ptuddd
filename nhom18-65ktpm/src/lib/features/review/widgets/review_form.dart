import 'package:flutter/material.dart';

import '../../../repositories/auth_repository.dart';
import '../data/supabase_review_repository.dart';
import '../review_rules.dart';

/// Mở bottom sheet đánh giá tiệm (UC-08). Trả về true nếu đã gửi thành công.
Future<bool> showReviewSheet(
  BuildContext context, {
  required String shopId,
  required String shopName,
}) async {
  final repo = SupabaseReviewRepository();
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: FutureBuilder(
        future: repo.myReview(shopId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final old = snapshot.data;
          return ReviewForm(
            shopName: shopName,
            initialRating: old?.rating,
            initialComment: old?.comment,
            onSubmit: (rating, comment) async {
              await repo.upsert(
                shopId: shopId,
                rating: rating,
                comment: comment,
              );
              if (context.mounted) Navigator.of(context).pop(true);
            },
          );
        },
      ),
    ),
  );

  if (sent == true && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Gửi đánh giá thành công')));
  }
  return sent == true;
}

class ReviewForm extends StatefulWidget {
  const ReviewForm({
    super.key,
    required this.shopName,
    required this.onSubmit,
    this.initialRating,
    this.initialComment,
  });

  final String shopName;
  final int? initialRating;
  final String? initialComment;

  /// Ném [AppException] để hiện lỗi ngay trên form.
  final Future<void> Function(int rating, String? comment) onSubmit;

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  late int? _rating = widget.initialRating;
  late final _comment = TextEditingController(text: widget.initialComment);
  bool _sending = false;
  bool _failed = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error =
        validateRating(_rating) ?? validateReviewComment(_comment.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_rating!, _comment.text);
    } on AppException catch (e) {
      // Giữ nguyên số sao và nội dung đã nhập để người dùng bấm "Thử lại".
      if (mounted) {
        setState(() {
          _error = e.message;
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.initialRating == null
              ? 'Đánh giá dịch vụ'
              : 'Sửa đánh giá của bạn',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(widget.shopName, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                tooltip: '$star sao',
                iconSize: 36,
                onPressed: _sending
                    ? null
                    : () => setState(() {
                        _rating = star;
                        _error = null;
                      }),
                icon: Icon(
                  star <= (_rating ?? 0) ? Icons.star : Icons.star_border,
                  color: Colors.amber.shade700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _comment,
          enabled: !_sending,
          maxLines: 4,
          maxLength: reviewCommentMaxLength,
          decoration: const InputDecoration(
            labelText: 'Nhận xét (không bắt buộc)',
          ),
          buildCounter: (
            _, {
            required currentLength,
            required isFocused,
            maxLength,
          }) => Text('Còn ${reviewCommentMaxLength - currentLength} ký tự'),
        ),
        if (_error != null) ...[
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 8),
        ],
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_failed ? 'Thử lại' : 'Gửi đánh giá'),
        ),
      ],
    );
  }
}
