import 'package:flutter_test/flutter_test.dart';
import 'package:ketnoitinhnguyenvienxemay/features/volunteer/volunteer_rules.dart';

void main() {
  test('validateSkills yêu cầu ít nhất 1 kỹ năng', () {
    expect(validateSkills([]), isNotNull);
    expect(validateSkills(['Vá xe']), isNull);
  });

  test('validateRadius khớp CHECK 1..20 km', () {
    expect(validateRadius(0), isNotNull);
    expect(validateRadius(1), isNull);
    expect(validateRadius(20), isNull);
    expect(validateRadius(21), isNotNull);
  });

  test('validateTools giới hạn 300 ký tự', () {
    expect(validateTools(null), isNull);
    expect(validateTools('a' * 300), isNull);
    expect(validateTools('a' * 301), isNotNull);
  });

  test('idCardContentType chỉ nhận định dạng bucket id-cards cho phép', () {
    expect(idCardContentType('cccd.JPG'), 'image/jpeg');
    expect(idCardContentType('a.jpeg'), 'image/jpeg');
    expect(idCardContentType('a.png'), 'image/png');
    expect(idCardContentType('a.webp'), 'image/webp');
    expect(idCardContentType('a.pdf'), isNull);
    expect(idCardContentType('khong-duoi'), isNull);
  });

  test('validateIdCard chặn sai định dạng và ảnh lớn hơn 5 MB', () {
    expect(validateIdCard(fileName: 'a.jpg', sizeBytes: 1024), isNull);
    expect(validateIdCard(fileName: 'a.gif', sizeBytes: 1024), isNotNull);
    expect(
      validateIdCard(fileName: 'a.jpg', sizeBytes: idCardMaxBytes + 1),
      isNotNull,
    );
  });

  test('ewktPoint ghi kinh độ trước vĩ độ', () {
    expect(
      ewktPoint(latitude: 21.0285, longitude: 105.8542),
      'SRID=4326;POINT(105.8542 21.0285)',
    );
  });

  test('volunteerStatusLabel có nhãn cho mọi trạng thái', () {
    for (final status in ['pending', 'approved', 'rejected', 'banned']) {
      expect(volunteerStatusLabel(status), isNotEmpty);
    }
  });
}
