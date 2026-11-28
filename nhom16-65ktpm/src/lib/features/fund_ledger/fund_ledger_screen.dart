import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/fund_transaction_model.dart';
import '../../data/repositories/fund_repository.dart';
import 'disbursement_form_screen.dart';
import 'widgets/fund_balance_card.dart';
import 'widgets/fund_filter_bar.dart';
import 'widgets/fund_transaction_card.dart';
import 'widgets/transaction_detail_sheet.dart';

/// Màn hình Sổ Quỹ Thu - Chi Từ Thiện (Charity Fund Ledger Screen)
/// Quản lý minh bạch toàn bộ dòng tiền tài trợ và các đợt giải ngân thiện nguyện
class FundLedgerScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAnalytics;
  final FundRepository? repository;

  const FundLedgerScreen({
    super.key,
    this.onNavigateToAnalytics,
    this.repository,
  });

  @override
  State<FundLedgerScreen> createState() => _FundLedgerScreenState();
}

class _FundLedgerScreenState extends State<FundLedgerScreen> {
  late final FundRepository _fundRepo;
  final TextEditingController _searchController = TextEditingController();

  double _balance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  List<FundTransactionModel> _allTransactions = [];
  List<FundTransactionModel> _filteredTransactions = [];

  TransactionType? _selectedTypeFilter; // null: Tất cả, thu: Thu, chi: Chi
  String? _selectedCategory; // null: Tất cả danh mục
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fundRepo = widget.repository ?? FundRepository.instance;
    _searchController.addListener(_onSearchChanged);
    _loadLedgerData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _loadLedgerData() async {
    setState(() => _isLoading = true);
    try {
      final balance = await _fundRepo.getBalance();
      final income = await _fundRepo.getTotalIncome();
      final expense = await _fundRepo.getTotalExpense();
      final transactions = await _fundRepo.getTransactions();

      if (mounted) {
        setState(() {
          _balance = balance;
          _totalIncome = income;
          _totalExpense = expense;
          _allTransactions = transactions;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải sổ quỹ: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredTransactions = _allTransactions.where((tx) {
        // 1. Lọc theo Loại Thu / Chi
        if (_selectedTypeFilter != null && tx.type != _selectedTypeFilter) {
          return false;
        }

        // 2. Lọc theo Danh mục
        if (_selectedCategory != null &&
            _selectedCategory != 'Tất cả' &&
            tx.category != _selectedCategory) {
          return false;
        }

        // 3. Tìm kiếm theo từ khoá
        if (query.isNotEmpty) {
          final titleMatch = tx.title.toLowerCase().contains(query);
          final recipientMatch =
              tx.recipientOrSponsor.toLowerCase().contains(query);
          final noteMatch = tx.note.toLowerCase().contains(query);
          final categoryMatch = tx.category.toLowerCase().contains(query);

          if (!titleMatch && !recipientMatch && !noteMatch && !categoryMatch) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _openDisbursementForm() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DisbursementFormScreen(currentBalance: _balance),
      ),
    );

    if (result == true) {
      _loadLedgerData();
    }
  }

  List<String> get _availableCategories {
    final categories =
        _allTransactions.map((tx) => tx.category).toSet().toList();
    categories.sort();
    return ['Tất cả', ...categories];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sổ Quỹ Thu - Chi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadLedgerData,
          ),
          if (widget.onNavigateToAnalytics != null)
            IconButton(
              tooltip: 'Xem biểu đồ phân tích',
              icon: const Icon(Icons.bar_chart_rounded),
              onPressed: widget.onNavigateToAnalytics,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadLedgerData,
              child: CustomScrollView(
                slivers: [
                  // 1. Thẻ Tổng Quan Số Dư Quỹ & Thu Chi (Commit 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: FundBalanceCard(
                        balance: _balance,
                        totalIncome: _totalIncome,
                        totalExpense: _totalExpense,
                        onDisbursePressed: _openDisbursementForm,
                      ),
                    ),
                  ),

                  // 2. Thanh Tìm kiếm & Bộ Lọc (Commit 2)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FundFilterBar(
                        searchController: _searchController,
                        selectedType: _selectedTypeFilter,
                        selectedCategory: _selectedCategory,
                        categories: _availableCategories,
                        onTypeChanged: (type) {
                          setState(() => _selectedTypeFilter = type);
                          _applyFilters();
                        },
                        onCategoryChanged: (cat) {
                          setState(() => _selectedCategory = cat);
                          _applyFilters();
                        },
                        onClearSearch: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // 3. Tiêu đề danh sách giao dịch & số lượng
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lịch sử biến động dòng tiền',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_filteredTransactions.length} giao dịch',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  // 4. Danh sách thẻ giao dịch (Commit 3 & Commit 4)
                  _filteredTransactions.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final tx = _filteredTransactions[index];
                                return FundTransactionCard(
                                  transaction: tx,
                                  onTap: () =>
                                      TransactionDetailSheet.show(context, tx),
                                );
                              },
                              childCount: _filteredTransactions.length,
                            ),
                          ),
                        ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fund_ledger_disburse_fab',
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: _openDisbursementForm,
        icon: const Icon(Icons.post_add_rounded),
        label: const Text(
          'Lập Phiếu Chi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Trạng thái trống khi không có giao dịch khớp bộ lọc
  Widget _buildEmptyState() {
    final hasActiveFilter = _searchController.text.isNotEmpty ||
        _selectedTypeFilter != null ||
        (_selectedCategory != null && _selectedCategory != 'Tất cả');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy giao dịch nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              hasActiveFilter
                  ? 'Thử thay đổi bộ lọc hoặc từ khoá tìm kiếm của bạn.'
                  : 'Chưa có biến động dòng tiền nào được ghi nhận trong sổ quỹ.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (hasActiveFilter)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedTypeFilter = null;
                    _selectedCategory = null;
                  });
                  _applyFilters();
                },
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Đặt lại bộ lọc'),
              )
            else
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed: _openDisbursementForm,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Lập Phiếu Chi Đầu Tiên'),
              ),
          ],
        ),
      ),
    );
  }
}
