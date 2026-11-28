/// Ba kiểu tóm tắt của #12 — khớp ràng buộc `mode` của bảng `summaries`
/// (`short` / `long` / `bullets`) trong `docs/co_so_du_lieu.md`.
enum SummaryMode {
  short('short'),
  long('long'),
  bullets('bullets');

  const SummaryMode(this.apiValue);

  /// Giá trị gửi lên máy chủ và lưu ở cột `mode`.
  final String apiValue;

  static SummaryMode fromApiValue(String value) {
    return values.firstWhere(
      (SummaryMode mode) => mode.apiValue == value,
      orElse: () => SummaryMode.short,
    );
  }
}
