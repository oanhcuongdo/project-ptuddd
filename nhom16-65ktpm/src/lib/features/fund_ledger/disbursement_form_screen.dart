import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/fund_transaction_model.dart';
import '../../data/repositories/fund_repository.dart';
import 'services/disbursement_receipt_storage_service.dart';
import 'widgets/disbursement_confirm_dialog.dart';
import 'widgets/receipt_attachment_card.dart';

/// Màn hình Lập Phiếu Chi Giải Ngân Từ Thiện (Disbursement Form Screen)
/// Cho phép Thủ quỹ / Quản trị viên lập lệnh chi tiền minh bạch, lưu trữ ảnh
/// sao kê / chuyển khoản thực tế vào bộ nhớ ứng dụng và đối soát trước khi ghi nhận.
class DisbursementFormScreen extends StatefulWidget {
  final double currentBalance;
  final FundRepository? repository;
  final DisbursementReceiptStorageService? storageService;

  const DisbursementFormScreen({
    super.key,
    required this.currentBalance,
    this.repository,
    this.storageService,
  });

  @override
  State<DisbursementFormScreen> createState() => _DisbursementFormScreenState();
}

class _DisbursementFormScreenState extends State<DisbursementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _transferRefController = TextEditingController();
  final _noteController = TextEditingController();

  late final FundRepository _fundRepo;
  late final DisbursementReceiptStorageService _storageService;

  final List<String> _categories = [
    'Hỗ trợ giáo dục & Trường học',
    'Cứu trợ thiên tai & Khẩn cấp',
    'Hỗ trợ y tế & Viện phí',
    'Chăm sóc trẻ em có hoàn cảnh khó khăn',
    'Bữa ăn tình thương & Thực phẩm',
    'Hoạt động thiện nguyện cộng đồng',
    'Khác',
  ];

  late String _selectedCategory;
  StoredReceiptImage? _storedReceipt;
  bool _isSavingReceipt = false;
  bool _isSubmitting = false;
  double _enteredAmount = 0.0;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _fundRepo = widget.repository ?? FundRepository.instance;
    _storageService =
        widget.storageService ?? const DisbursementReceiptStorageService();
    _selectedCategory = _categories.first;
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _titleController.dispose();
    _amountController.dispose();
    _recipientController.dispose();
    _transferRefController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = double.tryParse(digits) ?? 0.0;
    if (parsed != _enteredAmount) {
      setState(() => _enteredAmount = parsed);
    }
  }

  Future<void> _pickAndStoreReceipt(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isSavingReceipt = true);

      // Xoá ảnh cũ nếu người dùng chọn thay thế ảnh sao kê
      final previousPath = _storedReceipt?.savedPath;

      final stored = await _storageService.saveReceiptImage(
        pickedFile.path,
        disbursementRef: _transferRefController.text,
      );

      if (previousPath != null && previousPath != stored.savedPath) {
        await _storageService.deleteReceiptImage(previousPath);
      }

      if (mounted) {
        setState(() {
          _storedReceipt = stored;
          _isSavingReceipt = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingReceipt = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn hoặc lưu ảnh sao kê: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _removeReceipt() async {
    final path = _storedReceipt?.savedPath;
    setState(() => _storedReceipt = null);
    if (path != null) {
      await _storageService.deleteReceiptImage(path);
    }
  }

  void _selectQuickAmount(double amount) {
    _amountController.text = amount.toInt().toString();
  }

  String _composeFullNote() {
    final ref = _transferRefController.text.trim();
    final note = _noteController.text.trim();
    if (ref.isEmpty) return note;
    if (note.isEmpty) return 'Mã tham chiếu CK: $ref';
    return 'Mã tham chiếu CK: $ref\n$note';
  }

  Future<void> _submitDisbursement() async {
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền hợp lệ lớn hơn 0đ'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (amount > widget.currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Số tiền chi (${currencyFormatter.format(amount)}) vượt quá số dư quỹ hiện có (${currencyFormatter.format(widget.currentBalance)})!',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Đối soát lần cuối bằng DisbursementConfirmDialog
    final confirm = await DisbursementConfirmDialog.show(
      context,
      title: _titleController.text.trim(),
      amount: amount,
      currentBalance: widget.currentBalance,
      category: _selectedCategory,
      recipient: _recipientController.text.trim(),
      transferReference: _transferRefController.text.trim(),
      receiptFileName: _storedReceipt?.fileName,
    );

    if (!confirm || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final tx = FundTransactionModel(
        id: 'tx_exp_${now.millisecondsSinceEpoch}',
        type: TransactionType.chi,
        amount: amount,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        proofImagePath: _storedReceipt?.savedPath,
        note: _composeFullNote(),
        recipientOrSponsor: _recipientController.text.trim(),
        createdAt: now,
      );

      await _fundRepo.recordTransaction(tx);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lập phiếu chi thành công: -${currencyFormatter.format(amount)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi ghi nhận phiếu chi: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lập Phiếu Chi Giải Ngân'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thẻ thông tin số dư khả dụng & số dư dự kiến sau chi
              _buildBalanceSummaryCard(),

              const SizedBox(height: 20),

              // Trường 1: Tiêu đề khoản chi
              const Text(
                'Mục đích chi giải ngân *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'VD: Mua 50 bộ sách giáo khoa tặng học sinh nghèo',
                  prefixIcon:
                      const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập mục đích chi';
                  }
                  if (val.trim().length < 5) {
                    return 'Mục đích chi cần tối thiểu 5 ký tự';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Trường 2: Số tiền chi
              const Text(
                'Số tiền giải ngân (VNĐ) *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền (VD: 500000)',
                  prefixIcon:
                      const Icon(Icons.payments_rounded, color: AppColors.danger),
                  suffixText: 'VNĐ',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền chi';
                  }
                  final amount =
                      double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                  if (amount == null || amount <= 0) {
                    return 'Số tiền không hợp lệ';
                  }
                  if (amount > widget.currentBalance) {
                    return 'Vượt quá số dư quỹ hiện có';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // Gợi ý chọn số tiền nhanh
              _buildQuickAmountChips(),

              const SizedBox(height: 16),

              // Trường 3: Danh mục chi
              const Text(
                'Danh mục giải ngân *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.category_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Trường 4: Người / Đơn vị thụ hưởng
              const Text(
                'Đơn vị / Người thụ hưởng *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _recipientController,
                decoration: InputDecoration(
                  hintText: 'VD: Điểm trường Tiểu học Nậm Cần / Bà con vùng lũ',
                  prefixIcon: const Icon(
                    Icons.handshake_outlined,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập đơn vị hoặc người thụ hưởng';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Trường 5: Mã tham chiếu chuyển khoản ngân hàng
              const Text(
                'Mã tham chiếu chuyển khoản / Số uỷ nhiệm chi (tuỳ chọn)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _transferRefController,
                decoration: InputDecoration(
                  hintText: 'VD: FT263301234567 / VCB-20261126',
                  prefixIcon: const Icon(
                    Icons.confirmation_number_outlined,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Trường 6: Ghi chú diễn giải
              const Text(
                'Ghi chú / Chi tiết sử dụng quỹ (tuỳ chọn)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Nhập thông tin chi tiết về đợt giải ngân, địa điểm bàn giao, cam kết sử dụng...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // Trường 7: Đính kèm ảnh sao kê / chuyển khoản thực tế (Commit 2)
              const Text(
                'Đính kèm ảnh sao kê / Uỷ nhiệm chi thực tế',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ảnh sao kê sẽ được lưu trữ cục bộ an toàn để mọi thành viên có thể đối soát minh bạch.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              ReceiptAttachmentCard(
                receiptImage: _storedReceipt,
                isSaving: _isSavingReceipt,
                onPickFromGallery: () =>
                    _pickAndStoreReceipt(ImageSource.gallery),
                onPickFromCamera: () => _pickAndStoreReceipt(ImageSource.camera),
                onRemoveImage: _removeReceipt,
              ),

              const SizedBox(height: 28),

              // Nút Submit
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed:
                      (_isSubmitting || _isSavingReceipt) ? null : _submitDisbursement,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _isSubmitting ? 'Đang ghi nhận...' : 'Xác Nhận Lập Phiếu Chi',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSummaryCard() {
    final remaining = widget.currentBalance - _enteredAmount;
    final isOverLimit = _enteredAmount > widget.currentBalance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isOverLimit ? AppColors.danger : AppColors.primary)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isOverLimit ? AppColors.danger : AppColors.primary)
              .withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isOverLimit ? AppColors.danger : AppColors.primary)
                      .withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: isOverLimit ? AppColors.danger : AppColors.primaryDark,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số dư quỹ khả dụng hiện tại',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(widget.currentBalance),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isOverLimit
                            ? AppColors.danger
                            : AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_enteredAmount > 0) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOverLimit
                      ? 'Vượt hạn mức quỹ:'
                      : 'Số dư dự kiến sau giải ngân:',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  isOverLimit
                      ? '-${currencyFormatter.format(_enteredAmount - widget.currentBalance)}'
                      : currencyFormatter.format(remaining),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color:
                        isOverLimit ? AppColors.danger : AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAmountChips() {
    final chips = [
      100000.0,
      200000.0,
      500000.0,
      1000000.0,
      widget.currentBalance,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: chips
          .where((amt) => amt > 0 && amt <= widget.currentBalance)
          .map((amt) {
        final isMax = amt == widget.currentBalance;
        final label = isMax ? 'Toàn bộ số dư' : currencyFormatter.format(amt);

        return ActionChip(
          label: Text(label, style: const TextStyle(fontSize: 11)),
          backgroundColor: isMax ? AppColors.accentLight : null,
          onPressed: () => _selectQuickAmount(amt),
        );
      }).toList(),
    );
  }
}
