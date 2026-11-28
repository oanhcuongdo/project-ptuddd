import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/hci_components.dart';
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
  // Tạo Future một lần bên ngoài builder để tránh mở bàn phím làm rebuild reset form.
  final oldReviewFuture = repo.myReview(shopId);
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
        future: oldReviewFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final old = snapshot.hasError ? null : snapshot.data;
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
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _ratingCaption(int? rating) => switch (rating) {
    1 => 'Rất chưa hài lòng',
    2 => 'Cần cải thiện',
    3 => 'Ổn, chấp nhận được',
    4 => 'Dịch vụ tốt',
    5 => 'Tuyệt vời, rất hài lòng!',
    _ => 'Chạm vào số sao để đánh giá',
  };

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
        Text(
          widget.shopName,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var star = 1; star <= 5; star++)
                    AnimatedScale(
                      scale: star <= (_rating ?? 0) ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 160),
                      child: IconButton(
                        tooltip: '$star sao',
                        iconSize: 36,
                        onPressed: _sending
                            ? null
                            : () => setState(() {
                                _rating = star;
                                _error = null;
                              }),
                        icon: Icon(
                          star <= (_rating ?? 0)
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                _ratingCaption(_rating),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _rating == null
                      ? AppColors.inkMuted
                      : const Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _comment,
          enabled: !_sending,
          maxLines: 4,
          maxLength: reviewCommentMaxLength,
          decoration: const InputDecoration(
            labelText: 'Nhận xét (không bắt buộc)',
            hintText: 'Chia sẻ trải nghiệm sửa xe, thái độ phục vụ, giá cả...',
          ),
        ),
        if (_error != null) ...[
          FeedbackBanner(message: _error!, tone: FeedbackTone.error),
          const SizedBox(height: 10),
        ],
        FilledButton.icon(
          onPressed: _sending ? null : _submit,
          icon: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 18),
          label: const Text('Gửi đánh giá'),
        ),
      ],
    );
  }
}
