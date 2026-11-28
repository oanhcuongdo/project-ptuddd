// Dữ liệu mẫu phục vụ kiểm thử tích hợp OCR trong Sprint 1 - Sprint 3.
// Mô phỏng kết quả văn bản xuất hiện trên ảnh check-in đồng hồ và bài làm thực tế.

class MockOcrSample {
  const MockOcrSample({
    required this.id,
    required this.challengeId,
    required this.challengeTitle,
    required this.category,
    required this.sampleText,
    required this.description,
    this.expectedTime,
    this.isValidSample = true,
  });

  final String id;
  final String challengeId;
  final String challengeTitle;
  final String category;
  final String sampleText;
  final String description;
  final String? expectedTime;
  final bool isValidSample;
}

const List<MockOcrSample> mockOcrSamples = [
  MockOcrSample(
    id: 'sample_early_valid',
    challengeId: 'ch_01',
    challengeTitle: 'Dậy sớm học bài trước 06:00',
    category: 'Kỷ luật',
    sampleText:
        '05:42 AM - 22/11/2026\nÔn tập Lập trình Thiết bị Di động Flutter\nNhóm 16 - 65KTPM',
    description: 'Đồng hồ bàn học lúc 05:42 sáng (Hợp lệ < 06:00)',
    expectedTime: '05:42',
    isValidSample: true,
  ),
  MockOcrSample(
    id: 'sample_early_digital_clock',
    challengeId: 'ch_01',
    challengeTitle: 'Dậy sớm học bài trước 06:00',
    category: 'Kỷ luật',
    sampleText:
        'ALMW 5h18 - 22/11/2026\nBàn học sinh viên: Đọc giáo trình Clean Architecture & SQLite',
    description: 'Đồng hồ điện tử 5h18 sáng kèm giáo trình học bài',
    expectedTime: '05:18',
    isValidSample: true,
  ),
  MockOcrSample(
    id: 'sample_early_late',
    challengeId: 'ch_01',
    challengeTitle: 'Dậy sớm học bài trước 06:00',
    category: 'Kỷ luật',
    sampleText:
        '07:25 - Check-in bàn học buổi sáng\nĐọc tài liệu Clean Architecture',
    description: 'Ảnh chụp đồng hồ lúc 07:25 sáng (Trễ giờ quy định)',
    expectedTime: '07:25',
    isValidSample: false,
  ),
  MockOcrSample(
    id: 'sample_tutor',
    challengeId: 'ch_02',
    challengeTitle: 'Gia sư miễn phí cho trẻ em',
    category: 'Gia sư',
    sampleText:
        '19:00 - 22/11/2026 - Lớp học tình thương\nBài giảng: Toán tư duy & Phân số lớp 5\nSĩ số: 12 học sinh',
    description: 'Bảng viết lớp dạy học tình nguyện buổi tối',
    expectedTime: '19:00',
    isValidSample: true,
  ),
  MockOcrSample(
    id: 'sample_math_coding',
    challengeId: 'ch_03',
    challengeTitle: 'Giải toán & Lập trình mỗi ngày',
    category: 'Học tập',
    sampleText:
        '21:15 - LeetCode & Toán rời rạc\nHoàn thành 5 bài tập thuật toán Quy hoạch động & Cấu trúc dữ liệu\nPassed: 5/5 test cases',
    description: 'Màn hình/vở bài làm giải 5 bài toán & code thuật toán',
    expectedTime: '21:15',
    isValidSample: true,
  ),
  MockOcrSample(
    id: 'sample_running_strava',
    challengeId: 'ch_04',
    challengeTitle: 'Chạy bộ 3km hoặc rèn luyện thể thao',
    category: 'Sức khỏe',
    sampleText:
        '06:15 - Strava Running Activity\nDistance: 3.45 km | Pace: 5:40 /km | Time: 19m 33s',
    description: 'Màn hình ứng dụng Strava hoàn thành chạy bộ 3.45 km',
    expectedTime: '06:15',
    isValidSample: true,
  ),
];
