import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../repositories/auth_repository.dart';
import '../data/admin_statistics_repository.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({
    super.key,
    this.embedded = false,
    this.onOpenPending,
  });

  final bool embedded;

  /// Gọi khi Admin bấm thẻ "Hồ sơ chờ duyệt" để chuyển nhanh sang màn duyệt hồ sơ (UC-15 A2).
  final VoidCallback? onOpenPending;

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  final _repository = AdminStatisticsRepository();
  StatsPeriod _period = StatsPeriod.thirtyDays;
  DateTimeRange? _customRange;
  late Future<AdminStatisticsSnapshot> _future;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _future = _loadCurrent();
  }

  Future<AdminStatisticsSnapshot> _loadCurrent() => _repository.load(
    _period,
    customStart: _customRange?.start,
    customEnd: _customRange?.end,
  );

  Future<void> _reload() async {
    final next = _loadCurrent();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tải lại được thống kê.')),
        );
      }
    }
  }

  void _changePeriod(StatsPeriod? period) {
    if (period == null) return;
    setState(() {
      _period = period;
      _customRange = null;
      _future = _loadCurrent();
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial =
        _customRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: initial,
      helpText: 'Chọn khoảng thời gian thống kê (tối đa 365 ngày)',
      saveText: 'Áp dụng',
    );
    if (picked == null || !mounted) return;

    final err = validateStatsRange(picked.start, picked.end);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    setState(() {
      _customRange = picked;
      _future = _loadCurrent();
    });
  }

  Future<void> _exportCsv(AdminStatisticsSnapshot data) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final path = await _repository.saveCsvFile(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất tệp CSV: $path')),
      );
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không lưu được tệp CSV. Bạn có thể dùng Sao chép CSV.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _copyCsv(AdminStatisticsSnapshot data) async {
    await Clipboard.setData(ClipboardData(text: data.toCsv()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép dữ liệu CSV vào bộ nhớ tạm.'),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _kpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: onTap != null ? color : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: color, width: 3.5)),
        ),
        child: onTap != null ? InkWell(onTap: onTap, child: content) : content,
      ),
    );
  }

  Widget _kpiGrid(AdminStatisticsSnapshot data) {
    final avgText = data.avgCompletionMinutes == null
        ? '--'
        : '${data.avgCompletionMinutes!.toStringAsFixed(1)} ph';

    final cards = <Widget>[
      _kpiCard(
        label: 'Hồ sơ chờ duyệt',
        value: '${data.pendingCount}',
        subtitle:
            '${data.pendingShopCount} tiệm · ${data.pendingVolunteerCount} TNV',
        icon: Icons.pending_actions,
        color: const Color(0xFFE65100),
        onTap: widget.onOpenPending,
      ),
      _kpiCard(
        label: 'Ca SOS trong kỳ',
        value: '${data.sosCount}',
        subtitle:
            'Hoàn thành ${data.completedCount} (${(data.completionRate * 100).toStringAsFixed(0)}%)',
        icon: Icons.sos,
        color: const Color(0xFFC62828),
      ),
      _kpiCard(
        label: 'Thời gian xử lý TB',
        value: avgText,
        subtitle: 'Từ lúc gửi đến hoàn thành',
        icon: Icons.timer_outlined,
        color: const Color(0xFF4527A0),
      ),
      _kpiCard(
        label: 'Người dùng mới',
        value: '${data.userCount}',
        icon: Icons.people_outline,
        color: const Color(0xFF1565C0),
      ),
      _kpiCard(
        label: 'Tiệm sửa xe mới',
        value: '${data.repairShopCount}',
        icon: Icons.build_outlined,
        color: const Color(0xFFEF6C00),
      ),
      _kpiCard(
        label: 'Cây xăng mới',
        value: '${data.gasStationCount}',
        icon: Icons.local_gas_station_outlined,
        color: const Color(0xFF0277BD),
      ),
      _kpiCard(
        label: 'TNV đăng ký mới',
        value: '${data.volunteerCount}',
        icon: Icons.volunteer_activism_outlined,
        color: const Color(0xFF00695C),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 680 ? 3 : 2;
        const spacing = 10.0;
        final width = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }

  Widget _chart(AdminStatisticsSnapshot data) {
    final maximum = data.days.fold<int>(
      1,
      (previous, day) => day.sosCount > previous ? day.sosCount : previous,
    );
    const shopColor = Color(0xFF1565C0);
    const volColor = Color(0xFF00897B);
    const otherColor = Color(0xFFB0BEC5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biểu đồ yêu cầu SOS theo ngày',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _LegendDot(color: shopColor, label: 'Tiệm nhận'),
                _LegendDot(color: volColor, label: 'TNV nhận'),
                _LegendDot(color: otherColor, label: 'Chờ / Hủy'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final day in data.days)
                      Builder(
                        builder: (_) {
                          final totalHeight = day.sosCount == 0
                              ? 3.0
                              : (138.0 * day.sosCount / maximum).clamp(6.0, 138.0);
                          final other = (day.sosCount -
                                  day.shopAccepted -
                                  day.volunteerAccepted)
                              .clamp(0, day.sosCount);
                          final denom = day.sosCount == 0 ? 1 : day.sosCount;
                          return SizedBox(
                            width: 42,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  day.sosCount == 0 ? '' : '${day.sosCount}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 142,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: SizedBox(
                                        width: 20,
                                        height: totalHeight,
                                        child: day.sosCount == 0
                                            ? Container(color: otherColor)
                                            : Column(
                                                children: [
                                                  if (other > 0)
                                                    Expanded(
                                                      flex: other,
                                                      child: Container(
                                                        color: otherColor,
                                                      ),
                                                    ),
                                                  if (day.volunteerAccepted > 0)
                                                    Expanded(
                                                      flex: day.volunteerAccepted,
                                                      child: Container(
                                                        color: volColor,
                                                      ),
                                                    ),
                                                  if (day.shopAccepted > 0)
                                                    Expanded(
                                                      flex: day.shopAccepted,
                                                      child: Container(
                                                        color: shopColor,
                                                      ),
                                                    ),
                                                  if (day.shopAccepted +
                                                          day.volunteerAccepted +
                                                          other ==
                                                      0)
                                                    Expanded(
                                                      flex: denom,
                                                      child: Container(
                                                        color: otherColor,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${day.date.day}/${day.date.month}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topShopsCard(List<TopShopEntry> shops) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 5 tiệm đánh giá cao',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (shops.isEmpty)
              const Text('Chưa có tiệm nào được phê duyệt.')
            else
              for (var i = 0; i < shops.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: i == 0
                        ? const Color(0xFFFFF8E1)
                        : const Color(0xFFE3F2FD),
                    child: Text(
                      '#${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: i == 0
                            ? const Color(0xFFF57F17)
                            : const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  title: Text(
                    shops[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    shops[i].category == 'gas_station'
                        ? 'Cây xăng · ${shops[i].reviewCount} đánh giá'
                        : 'Tiệm sửa xe · ${shops[i].reviewCount} đánh giá',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 17, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        shops[i].rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _topVolunteersCard(List<TopVolunteerEntry> volunteers) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 5 tình nguyện viên hỗ trợ nhiều nhất',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (volunteers.isEmpty)
              const Text('Chưa có tình nguyện viên nào được phê duyệt.')
            else
              for (var i = 0; i < volunteers.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFE0F2F1),
                    child: Text(
                      '#${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00695C),
                      ),
                    ),
                  ),
                  title: Text(
                    volunteers[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(volunteers[i].phone),
                  trailing: Text(
                    '${volunteers[i].completedCount} ca',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00695C),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _statTable(AdminStatisticsSnapshot data) {
    final activeDays = data.days.where((day) => day.sosCount > 0).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiết SOS theo đơn vị tiếp nhận',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (activeDays.isEmpty)
              const Text('Chưa có ca SOS nào trong khoảng thời gian này.')
            else
              for (final day in activeDays)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_formatDate(day.date)),
                  subtitle: Text(
                    'Tiệm nhận: ${day.shopAccepted} · TNV nhận: ${day.volunteerAccepted}',
                  ),
                  trailing: Text(
                    '${day.sosCount} SOS',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = FutureBuilder<AdminStatisticsSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<StatsPeriod>(
                      initialValue: _period,
                      decoration: const InputDecoration(
                        labelText: 'Khoảng thời gian',
                      ),
                      items: [
                        for (final option in StatsPeriod.values)
                          DropdownMenuItem(
                            value: option,
                            child: Text(option.label),
                          ),
                      ],
                      onChanged: _changePeriod,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _pickCustomRange,
                    icon: const Icon(Icons.date_range, size: 18),
                    label: const Text('Tùy chọn'),
                  ),
                ],
              ),
              if (_customRange != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    avatar: const Icon(Icons.calendar_today, size: 15),
                    label: Text(
                      '${_formatDate(_customRange!.start)} – ${_formatDate(_customRange!.end)}',
                    ),
                    onDeleted: () {
                      setState(() {
                        _customRange = null;
                        _future = _loadCurrent();
                      });
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Không tải được thống kê: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _reload,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (data != null) ...[
                if (data.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Không có phát sinh mới trong khoảng thời gian đã chọn.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                _kpiGrid(data),
                const SizedBox(height: 12),
                _chart(data),
                _topShopsCard(data.topShops),
                _topVolunteersCard(data.topVolunteers),
                _statTable(data),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _exporting ? null : () => _exportCsv(data),
                        icon: _exporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: const Text('Xuất tệp CSV'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => _copyCsv(data),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Sao chép'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(
        title: const Text('UC-15: Thống kê hệ thống'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: content,
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
