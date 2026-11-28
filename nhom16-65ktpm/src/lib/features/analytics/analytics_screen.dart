import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/fund_transaction_model.dart';
import '../../data/repositories/fund_repository.dart';
import '../settings/settings_screen.dart';
import 'analytics_service.dart';
import 'report_exporter.dart';
import 'widgets/cashflow_bar_chart.dart';
import 'widgets/challenge_pie_chart.dart';
import 'widgets/fund_line_chart.dart';

// Màn hình Báo cáo & Thống kê minh bạch quỹ.
// Giai đoạn 4 - C9: toàn bộ màn hình (3 thẻ, tiến độ mục tiêu, 3 biểu đồ)
// dùng dữ liệu thật từ FundRepository.getTransactions; mục tiêu quỹ đọc
// từ Cài đặt (SharedPreferences), mặc định 100.000.000 đ khớp Dashboard;
// nút Xuất báo cáo ở thân màn hình bật popup ngay tại nút, trong popup
// là 2 nút lựa chọn bo tròn phân biệt màu (Xuất CSV xanh lá, Xuất PDF đỏ).
// Bổ sung: tự nạp lại số liệu khi quỹ thay đổi ở màn hình khác
// (duyệt minh chứng, giải ngân...) qua FundRepository.fundUpdateVersion;
// kéo xuống đầu danh sách để làm mới thủ công (RefreshIndicator).
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Mục tiêu quỹ mặc định 100 triệu; có thể đổi ở màn Cài đặt.
  double _fundGoal = 100000000.0;

  late Future<List<FundTransactionModel>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = FundRepository.instance.getTransactions();
    _loadGoal();
    FundRepository.instance.fundUpdateVersion.addListener(_onFundChanged);
  }

  @override
  void dispose() {
    FundRepository.instance.fundUpdateVersion.removeListener(_onFundChanged);
    super.dispose();
  }

  /// Quỹ vừa thay đổi ở màn hình khác (duyệt minh chứng, ghi giao
  /// dịch...) — nạp lại số liệu để Thống kê luôn khớp Sổ Quỹ,
  /// cùng cơ chế đồng bộ realtime mà Dashboard đang dùng.
  void _onFundChanged() {
    if (!mounted) return;
    _reload();
  }

  /// Đọc mục tiêu quỹ đã lưu trong Cài đặt (nếu chưa lưu thì giữ 100 triệu).
  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble('fund_goal');
    if (saved != null && saved > 0 && mounted) {
      setState(() {
        _fundGoal = saved;
      });
    }
  }

  /// Mở màn Cài đặt; quay lại thì đọc lại mục tiêu quỹ nếu đã đổi.
  Future<void> _openSettings() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(currentGoal: _fundGoal)),
    );
    if (changed == true) {
      _loadGoal();
    }
  }

  /// Một nút lựa chọn trong popup Xuất báo cáo: pill bo tròn có màu
  /// riêng cho từng định dạng (CSV xanh lá, PDF đỏ) kèm icon và chữ.
  Widget _exportChoiceButton(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  /// Xuất Sổ Quỹ ra file CSV (Giai đoạn 4 - C8).
  /// Lấy dữ liệu mới nhất từ FundRepository; file chèn BOM UTF-8 để
  /// Excel hiển thị đúng tiếng Việt. Windows lưu vào thư mục Downloads
  /// (hoặc hiện hộp thoại lưu), web tải file xuống trực tiếp.
  Future<void> _exportCsv() async {
    final txs = await FundRepository.instance.getTransactions();
    if (!mounted) return;
    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có giao dịch để xuất.')),
      );
      return;
    }
    final csv = const ReportExporter().buildCsv(txs);
    final bytes = Uint8List.fromList([
      0xEF, 0xBB, 0xBF, // BOM UTF-8 cho Excel đọc đúng tiếng Việt
      ...utf8.encode(csv),
    ]);
    final fileName =
        'bao_cao_quy_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    try {
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã xuất file CSV.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xuất CSV thất bại, thử lại sau.')),
      );
    }
  }

  /// Xuất báo cáo quỹ ra file PDF (Giai đoạn 4 - C9).
  /// Cùng nguồn dữ liệu với CSV; bản PDF có bảng kẻ border, dùng để
  /// in hoặc nộp báo cáo. Lưu bằng FileSaver giống CSV.
  Future<void> _exportPdf() async {
    final txs = await FundRepository.instance.getTransactions();
    if (!mounted) return;
    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có giao dịch để xuất.')),
      );
      return;
    }
    final fileName =
        'bao_cao_quy_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    try {
      final bytes = await const ReportExporter().buildPdf(txs);
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã xuất file PDF.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xuất PDF thất bại, thử lại sau.')),
      );
    }
  }

  /// Nạp lại danh sách giao dịch từ Sổ Quỹ.
  /// Gắn với nút "Thử lại" ở trạng thái lỗi và nút "Tải lại" ở trạng
  /// thái chưa có giao dịch, để không phải mở lại màn hình.
  void _reload() {
    setState(() {
      _transactionsFuture = FundRepository.instance.getTransactions();
    });
  }

  /// Kéo để làm mới: nạp lại giao dịch và chờ tải xong mới tắt
  /// vòng xoay của RefreshIndicator.
  Future<void> _onRefresh() async {
    _reload();
    await _transactionsFuture;
  }

  String _money(double v) =>
      '${NumberFormat.decimalPattern('vi_VN').format(v.round())} đ';

  Widget _summaryCard(String label, double value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 13)),
              Text(
                _money(value),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê quỹ từ thiện'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Cài đặt',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: FutureBuilder<List<FundTransactionModel>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Đang tải số liệu...'),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Không tải được số liệu quỹ.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          final txs = snapshot.data ?? const <FundTransactionModel>[];
          if (txs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text('Chưa có giao dịch quỹ.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại'),
                  ),
                ],
              ),
            );
          }

          const service = AnalyticsService();
          final income = service.totalIncome(txs);
          final expense = service.totalExpense(txs);
          final balance = service.balance(txs);
          final goalProgress = (balance / _fundGoal).clamp(0.0, 1.0);

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    _summaryCard(
                      'Tổng thu',
                      income,
                      Colors.green,
                      Icons.arrow_downward,
                    ),
                    _summaryCard(
                      'Tổng chi',
                      expense,
                      Colors.red,
                      Icons.arrow_upward,
                    ),
                    _summaryCard(
                      'Số dư',
                      balance,
                      Colors.blue,
                      Icons.account_balance_wallet,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Tiến độ mục tiêu: ${_money(balance)} / ${_money(_fundGoal)}',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: goalProgress),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PopupMenuButton<String>(
                    position: PopupMenuPosition.under,
                    tooltip: 'Xuất báo cáo',
                    onSelected: (value) {
                      if (value == 'csv') _exportCsv();
                      if (value == 'pdf') _exportPdf();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'csv',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: _exportChoiceButton(
                          Icons.table_chart,
                          'Xuất CSV',
                          Colors.green.shade700,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: _exportChoiceButton(
                          Icons.picture_as_pdf,
                          'Xuất PDF',
                          Colors.red.shade700,
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Xuất báo cáo',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Biến động số dư (7 ngày)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FundLineChart(points: service.balanceByDay(txs)),
                const SizedBox(height: 24),
                const Text(
                  'Thu / chi theo tháng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CashflowBarChart(points: service.incomeExpenseByMonth(txs)),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.square, color: Colors.green, size: 14),
                    Text(' Thu   '),
                    Icon(Icons.square, color: Colors.red, size: 14),
                    Text(' Chi'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Đóng góp theo danh mục',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ChallengePieChart(shares: service.contributionByChallenge(txs)),
              ],
            ),
          );
        },
      ),
    );
  }
}
