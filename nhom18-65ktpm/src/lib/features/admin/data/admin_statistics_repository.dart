import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/supabase_client.dart';
import '../../../core/supabase_errors.dart';
import '../../../repositories/auth_repository.dart';

enum StatsPeriod { sevenDays, thirtyDays, currentMonth }

extension StatsPeriodLabel on StatsPeriod {
  String get label => switch (this) {
    StatsPeriod.sevenDays => '7 ngày gần nhất',
    StatsPeriod.thirtyDays => '30 ngày gần nhất',
    StatsPeriod.currentMonth => 'Tháng hiện tại',
  };

  DateTime startDate(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      StatsPeriod.sevenDays => today.subtract(const Duration(days: 6)),
      StatsPeriod.thirtyDays => today.subtract(const Duration(days: 29)),
      StatsPeriod.currentMonth => DateTime(now.year, now.month, 1),
    };
  }
}

/// Kiểm tra khoảng ngày tùy chọn theo UC-15 E2 (tối đa 365 ngày).
String? validateStatsRange(DateTime start, DateTime end) {
  final startDay = DateTime(start.year, start.month, start.day);
  final endDay = DateTime(end.year, end.month, end.day);
  if (startDay.isAfter(endDay)) {
    return 'Ngày bắt đầu phải nhỏ hơn hoặc bằng ngày kết thúc.';
  }
  if (endDay.difference(startDay).inDays > 365) {
    return 'Khoảng thời gian thống kê tối đa 365 ngày.';
  }
  return null;
}

class StatsDay {
  const StatsDay({
    required this.date,
    required this.sosCount,
    required this.shopAccepted,
    required this.volunteerAccepted,
  });

  final DateTime date;
  final int sosCount;
  final int shopAccepted;
  final int volunteerAccepted;
}

class TopShopEntry {
  const TopShopEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviewCount,
  });

  final String id;
  final String name;
  final String category;
  final double rating;
  final int reviewCount;
}

class TopVolunteerEntry {
  const TopVolunteerEntry({
    required this.id,
    required this.name,
    required this.phone,
    required this.completedCount,
  });

  final String id;
  final String name;
  final String phone;
  final int completedCount;
}

class AdminStatisticsSnapshot {
  const AdminStatisticsSnapshot({
    required this.period,
    required this.startDate,
    this.endDate,
    this.isCustomRange = false,
    required this.userCount,
    required this.repairShopCount,
    required this.gasStationCount,
    required this.volunteerCount,
    required this.sosCount,
    required this.completedCount,
    this.pendingShopCount = 0,
    this.pendingVolunteerCount = 0,
    this.avgCompletionMinutes,
    this.topShops = const [],
    this.topVolunteers = const [],
    required this.days,
  });

  final StatsPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCustomRange;
  final int userCount;
  final int repairShopCount;
  final int gasStationCount;
  final int volunteerCount;
  final int sosCount;
  final int completedCount;
  final int pendingShopCount;
  final int pendingVolunteerCount;
  final double? avgCompletionMinutes;
  final List<TopShopEntry> topShops;
  final List<TopVolunteerEntry> topVolunteers;
  final List<StatsDay> days;

  int get shopCount => repairShopCount + gasStationCount;
  int get pendingCount => pendingShopCount + pendingVolunteerCount;
  double get completionRate => sosCount == 0 ? 0 : completedCount / sosCount;
  bool get isEmpty =>
      userCount == 0 && shopCount == 0 && volunteerCount == 0 && sosCount == 0;

  String toCsv() {
    final avgText = avgCompletionMinutes == null
        ? ''
        : avgCompletionMinutes!.toStringAsFixed(1);
    final lines = <String>[
      'ngay,so_sos,tiem_tiep_nhan,tnv_tiep_nhan',
      for (final day in days)
        '${_dateKey(day.date)},${day.sosCount},${day.shopAccepted},${day.volunteerAccepted}',
      '',
      'chi_so,gia_tri',
      'nguoi_dung_moi,$userCount',
      'tiem_sua_xe_moi,$repairShopCount',
      'cay_xang_moi,$gasStationCount',
      'tnv_moi,$volunteerCount',
      'sos_moi,$sosCount',
      'sos_hoan_thanh,$completedCount',
      'ty_le_hoan_thanh_pct,${(completionRate * 100).toStringAsFixed(1)}',
      'thoi_gian_xu_ly_tb_phut,$avgText',
      'ho_so_cho_duyet,$pendingCount',
    ];
    return lines.join('\r\n');
  }
}

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

class AdminStatisticsRepository {
  Future<void> _requireAdmin() async {
    final id = supabase.auth.currentUser?.id;
    if (id == null) {
      throw const AppException('Bạn cần đăng nhập.');
    }
    final row = await supabase
        .from('users')
        .select('role,status')
        .eq('id', id)
        .maybeSingle();
    if (row == null || row['role'] != 'admin' || row['status'] != 'active') {
      throw const AppException('Bạn không có quyền xem thống kê.');
    }
  }

  Future<AdminStatisticsSnapshot> load(
    StatsPeriod period, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return guardSupabase(() async {
      await _requireAdmin();
      final now = DateTime.now();
      final isCustom = customStart != null && customEnd != null;
      late final DateTime startDay;
      late final DateTime endDay;
      late final DateTime endBoundary;

      if (isCustom) {
        final err = validateStatsRange(customStart, customEnd);
        if (err != null) throw AppException(err);
        startDay = DateTime(
          customStart.year,
          customStart.month,
          customStart.day,
        );
        endDay = DateTime(customEnd.year, customEnd.month, customEnd.day);
        endBoundary = DateTime(
          endDay.year,
          endDay.month,
          endDay.day,
          23,
          59,
          59,
          999,
        );
      } else {
        startDay = period.startDate(now);
        endDay = DateTime(now.year, now.month, now.day);
        endBoundary = now;
      }

      final startIso = startDay.toUtc().toIso8601String();
      final endIso = endBoundary.toUtc().toIso8601String();

      final results = await Future.wait<List<Map<String, dynamic>>>([
        supabase
            .from('users')
            .select('id,created_at')
            .gte('created_at', startIso)
            .lte('created_at', endIso),
        supabase
            .from('shops')
            .select('id,category,created_at')
            .gte('created_at', startIso)
            .lte('created_at', endIso),
        supabase
            .from('volunteer_profiles')
            .select('id,created_at')
            .gte('created_at', startIso)
            .lte('created_at', endIso),
        supabase
            .from('sos_requests')
            .select(
              'id,status,created_at,completed_at,accepted_shop_id,accepted_volunteer_id',
            )
            .gte('created_at', startIso)
            .lte('created_at', endIso),
        supabase.from('shops').select('id').eq('status', 'pending'),
        supabase
            .from('volunteer_profiles')
            .select('id')
            .eq('status', 'pending'),
        supabase
            .from('shops')
            .select('id,name,category,rating,review_count')
            .eq('status', 'approved')
            .order('rating', ascending: false)
            .order('review_count', ascending: false)
            .limit(5),
        supabase
            .from('volunteer_profiles')
            .select('id,user_id,phone,completed_count')
            .eq('status', 'approved')
            .order('completed_count', ascending: false)
            .limit(5),
      ]);

      final userRows = results[0];
      final shopRows = results[1];
      final volunteerRows = results[2];
      final sosRows = results[3];
      final pendingShopRows = results[4];
      final pendingVolunteerRows = results[5];
      final topShopRows = results[6];
      final topVolunteerRows = results[7];

      final totals = <String, int>{};
      final shops = <String, int>{};
      final volunteers = <String, int>{};
      var completedDurationMinutes = 0.0;
      var completedWithDuration = 0;

      for (final row in sosRows) {
        final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
        if (createdAt == null) continue;
        final key = _dateKey(createdAt.toLocal());
        totals[key] = (totals[key] ?? 0) + 1;
        if (row['accepted_shop_id'] != null) {
          shops[key] = (shops[key] ?? 0) + 1;
        }
        if (row['accepted_volunteer_id'] != null) {
          volunteers[key] = (volunteers[key] ?? 0) + 1;
        }
        if (row['status'] == 'completed' && row['completed_at'] != null) {
          final completedAt = DateTime.tryParse(row['completed_at'].toString());
          if (completedAt != null && completedAt.isAfter(createdAt)) {
            completedDurationMinutes +=
                completedAt.difference(createdAt).inSeconds / 60.0;
            completedWithDuration++;
          }
        }
      }

      final days = <StatsDay>[];
      for (
        var day = startDay;
        !day.isAfter(endDay);
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        final key = _dateKey(day);
        days.add(
          StatsDay(
            date: day,
            sosCount: totals[key] ?? 0,
            shopAccepted: shops[key] ?? 0,
            volunteerAccepted: volunteers[key] ?? 0,
          ),
        );
      }

      final topShops = topShopRows
          .map(
            (r) => TopShopEntry(
              id: r['id'] as String,
              name: (r['name'] as String?) ?? '',
              category: (r['category'] as String?) ?? 'repair_shop',
              rating: (r['rating'] as num?)?.toDouble() ?? 0,
              reviewCount: (r['review_count'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList();

      final volunteerUserIds = topVolunteerRows
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final nameByUserId = <String, String>{};
      if (volunteerUserIds.isNotEmpty) {
        final volUsers = await supabase
            .from('users')
            .select('id,full_name')
            .inFilter('id', volunteerUserIds);
        for (final row in volUsers) {
          nameByUserId[row['id'] as String] =
              (row['full_name'] as String?) ?? '';
        }
      }

      final topVolunteers = topVolunteerRows
          .map((r) {
            final uid = r['user_id'] as String? ?? '';
            final phone = (r['phone'] as String?) ?? '';
            final name = nameByUserId[uid]?.trim() ?? '';
            return TopVolunteerEntry(
              id: r['id'] as String,
              name: name.isNotEmpty ? name : 'TNV ($phone)',
              phone: phone,
              completedCount: (r['completed_count'] as num?)?.toInt() ?? 0,
            );
          })
          .toList();

      return AdminStatisticsSnapshot(
        period: period,
        startDate: startDay,
        endDate: endDay,
        isCustomRange: isCustom,
        userCount: userRows.length,
        repairShopCount: shopRows
            .where((row) => row['category'] == 'repair_shop')
            .length,
        gasStationCount: shopRows
            .where((row) => row['category'] == 'gas_station')
            .length,
        volunteerCount: volunteerRows.length,
        sosCount: sosRows.length,
        completedCount: sosRows
            .where((row) => row['status'] == 'completed')
            .length,
        pendingShopCount: pendingShopRows.length,
        pendingVolunteerCount: pendingVolunteerRows.length,
        avgCompletionMinutes: completedWithDuration == 0
            ? null
            : completedDurationMinutes / completedWithDuration,
        topShops: topShops,
        topVolunteers: topVolunteers,
        days: days,
      );
    });
  }

  /// Xuất tệp CSV (UTF-8 BOM để mở trực tiếp bằng Excel không lỗi tiếng Việt).
  Future<String> saveCsvFile(AdminStatisticsSnapshot data) async {
    if (kIsWeb) {
      throw const AppException(
        'Xuất tệp chưa hỗ trợ trên trình duyệt. Hãy dùng "Sao chép CSV".',
      );
    }
    final from = _dateKey(data.startDate);
    final to = _dateKey(data.endDate ?? DateTime.now());
    final fileName = 'thong-ke_${from}_$to.csv';
    final content = '\uFEFF${data.toCsv()}';

    // Ưu tiên thư mục Download trên Android nếu ghi được, ngược lại dùng thư mục tạm hệ thống.
    final candidates = <Directory>[
      if (Platform.isAndroid) Directory('/storage/emulated/0/Download'),
      Directory.systemTemp,
    ];

    for (final dir in candidates) {
      try {
        if (!await dir.exists()) continue;
        final file = File('${dir.path}${Platform.pathSeparator}$fileName');
        await file.writeAsString(content, flush: true);
        return file.path;
      } catch (_) {
        continue;
      }
    }
    throw const AppException('Không ghi được tệp CSV trên thiết bị.');
  }
}
