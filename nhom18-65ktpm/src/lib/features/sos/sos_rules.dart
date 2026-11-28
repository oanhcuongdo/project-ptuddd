/// Quy tắc và định dạng dùng chung cho UC-07 / UC-12, tách khỏi widget để test.
library;

/// Khớp CHECK issue_type trong 01_schema.sql.
const sosIssueTypes = ['Hết xăng', 'Thủng lốp', 'Hỏng động cơ', 'Khác'];

const sosNoteMaxLength = 300;
const sosTimeout = Duration(minutes: 5);
const sosPopupAutoDismiss = Duration(seconds: 60);

/// Danh sách hotline dự phòng khi không có tiệm/TNV quanh khu vực (UC-07).
const emergencyHotlines = [
  (label: 'Cảnh sát khẩn cấp (113)', phone: '113'),
  (label: 'Cấp cứu y tế (115)', phone: '115'),
  (label: 'Cứu hộ cứu nạn (114)', phone: '114'),
];

String? validateSosNote(String? value) {
  if ((value?.trim().length ?? 0) > sosNoteMaxLength) {
    return 'Ghi chú tối đa $sosNoteMaxLength ký tự';
  }
  return null;
}

String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String formatAgo(DateTime? time, {DateTime? now}) {
  if (time == null) return '';
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'vừa xong';
  if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
  if (diff.inDays < 1) return '${diff.inHours} giờ trước';
  return '${diff.inDays} ngày trước';
}

/// Mở Google Maps ngoài để chỉ đường tới điểm sự cố.
Uri directionsUri(double latitude, double longitude) {
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '$latitude,$longitude',
    'travelmode': 'driving',
  });
}
