import 'package:flutter_test/flutter_test.dart';
import 'package:ketnoitinhnguyenvienxemay/features/admin/data/admin_statistics_repository.dart';

void main() {
  group('AdminStatistics - UC-15', () {
    test('validateStatsRange kiểm tra thứ tự ngày và giới hạn 365 ngày', () {
      final start = DateTime(2026, 1, 1);
      final validEnd = DateTime(2026, 12, 31);
      final tooLongEnd = DateTime(2027, 1, 5);

      expect(validateStatsRange(start, start), isNull);
      expect(validateStatsRange(start, validEnd), isNull);
      expect(validateStatsRange(validEnd, start), isNotNull);
      expect(validateStatsRange(start, tooLongEnd), isNotNull);
    });

    test('AdminStatisticsSnapshot tính tỷ lệ, chờ duyệt và xuất CSV đầy đủ', () {
      final snapshot = AdminStatisticsSnapshot(
        period: StatsPeriod.sevenDays,
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 2),
        userCount: 10,
        repairShopCount: 3,
        gasStationCount: 2,
        volunteerCount: 4,
        sosCount: 8,
        completedCount: 6,
        pendingShopCount: 2,
        pendingVolunteerCount: 1,
        avgCompletionMinutes: 17.5,
        days: [
          StatsDay(
            date: DateTime(2026, 4, 1),
            sosCount: 5,
            shopAccepted: 3,
            volunteerAccepted: 1,
          ),
          StatsDay(
            date: DateTime(2026, 4, 2),
            sosCount: 3,
            shopAccepted: 1,
            volunteerAccepted: 2,
          ),
        ],
      );

      expect(snapshot.shopCount, 5);
      expect(snapshot.pendingCount, 3);
      expect(snapshot.completionRate, closeTo(0.75, 1e-6));
      expect(snapshot.isEmpty, isFalse);

      final csv = snapshot.toCsv();
      expect(csv, contains('2026-04-01,5,3,1'));
      expect(csv, contains('2026-04-02,3,1,2'));
      expect(csv, contains('thoi_gian_xu_ly_tb_phut,17.5'));
      expect(csv, contains('ho_so_cho_duyet,3'));
    });
  });
}
