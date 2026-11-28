/// Quy tắc nhập liệu UC-08, tách khỏi widget để test.
library;

const reviewCommentMaxLength = 500;

String? validateRating(int? rating) {
  if (rating == null || rating < 1 || rating > 5) {
    return 'Vui lòng chọn số sao trước khi gửi';
  }
  return null;
}

String? validateReviewComment(String? value) {
  if ((value?.trim().length ?? 0) > reviewCommentMaxLength) {
    return 'Nội dung nhận xét không được vượt quá $reviewCommentMaxLength ký tự';
  }
  return null;
}
