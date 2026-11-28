/// Quy tắc hồ sơ tình nguyện viên (UC-13), tách khỏi widget để test.
library;

const volunteerSkillOptions = [
  'Vá xe',
  'Kích bình',
  'Tiếp xăng',
  'Kéo xe',
  'Sửa điện',
  'Khác',
];

/// Khớp CHECK service_radius_km trong 01_schema.sql.
const volunteerMinRadiusKm = 1;
const volunteerMaxRadiusKm = 20;
const volunteerDefaultRadiusKm = 5;
const volunteerQuickRadiiKm = [3, 5, 10];

const volunteerToolsMaxLength = 300;

/// Khớp file_size_limit của bucket id-cards trong 04_storage.sql.
const idCardMaxBytes = 5 * 1024 * 1024;

String? validateSkills(List<String> skills) {
  return skills.isEmpty ? 'Chọn ít nhất 1 kỹ năng hỗ trợ' : null;
}

String? validateRadius(int km) {
  if (km < volunteerMinRadiusKm || km > volunteerMaxRadiusKm) {
    return 'Bán kính hỗ trợ phải từ $volunteerMinRadiusKm đến $volunteerMaxRadiusKm km';
  }
  return null;
}

String? validateTools(String? value) {
  if ((value?.trim().length ?? 0) > volunteerToolsMaxLength) {
    return 'Dụng cụ tối đa $volunteerToolsMaxLength ký tự';
  }
  return null;
}

/// MIME type cho phép của bucket id-cards, null nếu không hỗ trợ.
String? idCardContentType(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final ext = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
  }
  return null;
}

String? validateIdCard({required String fileName, required int sizeBytes}) {
  if (idCardContentType(fileName) == null) {
    return 'Ảnh giấy tờ phải có định dạng JPG, PNG hoặc WEBP';
  }
  if (sizeBytes > idCardMaxBytes) {
    return 'Ảnh giấy tờ không được vượt quá 5 MB';
  }
  return null;
}

/// Định dạng PostGIS nhận cho cột geography qua PostgREST.
String ewktPoint({required double latitude, required double longitude}) {
  return 'SRID=4326;POINT($longitude $latitude)';
}

String volunteerStatusLabel(String status, {String? rejectionReason}) {
  switch (status) {
    case 'approved':
      return 'Đã được duyệt';
    case 'rejected':
      final reason = rejectionReason?.trim() ?? '';
      return reason.isEmpty
          ? 'Bị từ chối, vui lòng sửa và gửi lại'
          : 'Bị từ chối: $reason. Vui lòng sửa và gửi lại';
    case 'banned':
      return 'Đã bị khóa';
    default:
      return 'Đang chờ Quản trị viên duyệt';
  }
}
