import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_section_header.dart';
import '../models/saving_plan.dart';
import '../providers/receipt_approval_provider.dart';
import '../utils/momo_deeplink_helper.dart';
import '../utils/momo_launcher.dart';
import 'widgets/module_notification.dart';
import 'widgets/module_provider_scope.dart';

/// Modal Sheet Nạp Quỹ MoMo & Nộp Biên Lai (Dành cho Thành viên).
/// Thiết kế 2 bước rõ ràng: Bước 1 mở MoMo (kèm QR & Copy fallback) -> Bước 2 tải biên lai & cảm xúc DailyYou.
class DepositReceiptSheet extends StatelessWidget {
  const DepositReceiptSheet({
    super.key,
    required this.fundName,
    this.tripId = 'trip_demo_01',
    this.memberId = 'member_demo_01',
    this.memberName = 'Thành viên',
    this.amount = 212000,
    this.installmentIndex = 1,
    this.cycleLabel = 'Kỳ hiện tại',
    this.termDueDate,
    this.termFrequency,
    this.momoLink,
    this.phoneNumber,
    this.qrData,
    this.allowAmountEdit = false,
  });

  final String fundName;
  final String tripId;
  final String memberId;
  final String memberName;
  final double amount;
  final int installmentIndex;
  final String cycleLabel;
  final DateTime? termDueDate;
  final SavingFrequency? termFrequency;
  final String? momoLink;
  final String? phoneNumber;
  final String? qrData;
  final bool allowAmountEdit;

  @override
  Widget build(BuildContext context) {
    return ModuleProviderScope(
      child: _DepositReceiptContent(
        fundName: fundName,
        tripId: tripId,
        memberId: memberId,
        memberName: memberName,
        amount: amount,
        installmentIndex: installmentIndex,
        cycleLabel: cycleLabel,
        termDueDate: termDueDate,
        termFrequency: termFrequency,
        momoLink: momoLink,
        phoneNumber: phoneNumber,
        qrData: qrData,
        allowAmountEdit: allowAmountEdit,
      ),
    );
  }
}

class _DepositReceiptContent extends ConsumerStatefulWidget {
  const _DepositReceiptContent({
    required this.fundName,
    required this.tripId,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.installmentIndex,
    required this.cycleLabel,
    this.termDueDate,
    this.termFrequency,
    this.momoLink,
    this.phoneNumber,
    this.qrData,
    this.allowAmountEdit = false,
  });

  final String fundName;
  final String tripId;
  final String memberId;
  final String memberName;
  final double amount;
  final int installmentIndex;
  final String cycleLabel;
  final DateTime? termDueDate;
  final SavingFrequency? termFrequency;
  final String? momoLink;
  final String? phoneNumber;
  final String? qrData;
  final bool allowAmountEdit;

  @override
  ConsumerState<_DepositReceiptContent> createState() => _DepositReceiptContentState();
}

class _DepositReceiptContentState extends ConsumerState<_DepositReceiptContent> {
  final _noteCtrl = TextEditingController(text: 'Nhịn 2 ly trà sữa góp quỹ đúng hạn!');
  late final TextEditingController _amountCtrl;
  final _moods = const ['🔥', '😎', '🚀', '💪', '🎉'];
  int _selectedMood = 0;
  bool _showQrFallback = false;
  bool _isSubmitting = false;
  bool _cameraPermanentlyDenied = false;
  File? _receiptImage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: MoMoDeeplinkHelper.formatDigitsWithDots(widget.amount.round()),
    );
  }

  double get _effectiveAmount {
    if (!widget.allowAmountEdit) return widget.amount;
    final digits = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0.0;
    return double.tryParse(digits) ?? 0.0;
  }

  Future<void> _launchMoMo(String link, String copySummary) async {
    final launched = await MoMoLauncher.openMoMo(
      context,
      deeplink: link,
      copySummary: copySummary,
    );
    if (!launched && mounted) {
      setState(() => _showQrFallback = true);
    }
  }

  Future<void> _pickReceiptImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Chụp ảnh biên lai mới'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    if (source == ImageSource.camera) {
      final hasPermission = await _ensureCameraPermission();
      if (!hasPermission || !mounted) return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _receiptImage = File(picked.path);
          _errorMessage = null;
          _cameraPermanentlyDenied = false;
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code == 'camera_access_denied') {
        setState(() {
          _cameraPermanentlyDenied = true;
          _errorMessage =
              'Cần quyền truy cập camera để chụp ảnh biên lai. Vui lòng bật quyền Camera trong Cài đặt.';
        });
      } else {
        setState(() => _errorMessage = 'Không thể chọn ảnh biên lai: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Không thể chọn ảnh biên lai: $e');
    }
  }

  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted &&
        !status.isPermanentlyDenied &&
        !status.isRestricted) {
      status = await Permission.camera.request();
    }
    if (!mounted) return false;
    if (status.isGranted) {
      setState(() => _cameraPermanentlyDenied = false);
      return true;
    }

    final permDenied = status.isPermanentlyDenied || status.isRestricted;
    setState(() {
      _cameraPermanentlyDenied = permDenied;
      _errorMessage = permDenied
          ? 'Quyền camera đã bị từ chối vĩnh viễn. Vui lòng bật quyền Camera trong Cài đặt ứng dụng.'
          : 'Cần quyền truy cập camera để chụp ảnh biên lai.';
    });
    return false;
  }

  Future<void> _submitReceipt() async {
    if (_isSubmitting) return;
    if (_receiptImage == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn ảnh chụp biên lai giao dịch MoMo';
      });
      return;
    }

    if (_effectiveAmount <= 0) {
      setState(() {
        _errorMessage = 'Vui lòng nhập số tiền nạp quỹ hợp lệ (> 0đ)';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(receiptApprovalProvider(widget.tripId).notifier).submitDeposit(
            memberId: widget.memberId,
            memberName: widget.memberName,
            amount: _effectiveAmount,
            installmentIndex: widget.installmentIndex,
            termDueDate: widget.termDueDate,
            termFrequency: widget.termFrequency,
            receiptImage: _receiptImage,
            note: _noteCtrl.text,
            emotionTag: _moods[_selectedMood],
          );

      if (!mounted) return;
      Navigator.pop(context, true);
      ModuleNotification.success(
        context,
        'Đã gửi biên lai! Trạng thái chuyển sang Chờ Trưởng nhóm duyệt.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gửi biên lai thất bại: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transferNote = MoMoDeeplinkHelper.buildTransferNote(
      tripId: widget.tripId,
      memberName: widget.memberName,
    );
    final formattedAmount = MoMoDeeplinkHelper.formatVnd(_effectiveAmount.round());
    final effectiveLink = (widget.momoLink?.isNotEmpty == true)
        ? widget.momoLink!
        : (widget.phoneNumber?.isNotEmpty == true
            ? MoMoDeeplinkHelper.buildFallbackLink(widget.phoneNumber!)
            : '');
    final qrData = (widget.qrData?.isNotEmpty == true) ? widget.qrData! : effectiveLink;
    final receiptFileName = _receiptImage?.path.split(Platform.pathSeparator).last;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nạp quỹ ${widget.cycleLabel}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.fundName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.outlineVariantSoft),
                        ),
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.outlineVariantSoft),
              const SizedBox(height: 14),

              // BƯỚC 1: Mở MoMo + Fallback QR / Copy
              const AppSectionHeader(title: 'Bước 1 — Chuyển tiền vào Quỹ nhóm MoMo'),
              AppInsetCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      formattedAmount,
                      style: AppTheme.monoAmount(fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                    if (widget.allowAmountEdit) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsDotInputFormatter()],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Số tiền nộp quỹ (VNĐ)',
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.outlineVariantSoft),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineVariantSoft),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.tag_rounded,
                            size: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              transferNote,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppPrimaryButton(
                      label: 'Mở ứng dụng MoMo ngay',
                      icon: Icons.open_in_new,
                      backgroundColor: AppColors.momo,
                      onPressed: effectiveLink.isEmpty
                          ? null
                          : () {
                              _launchMoMo(
                                effectiveLink,
                                widget.phoneNumber?.isNotEmpty == true
                                    ? widget.phoneNumber!
                                    : transferNote,
                              );
                            },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: qrData.isEmpty
                                ? null
                                : () => setState(() => _showQrFallback = !_showQrFallback),
                            icon: const Icon(Icons.qr_code_2, size: 18),
                            label: Text(_showQrFallback ? 'Ẩn mã QR' : 'Hiện mã QR'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.onSurface,
                              side: const BorderSide(color: AppColors.outlineVariantSoft),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: '${_effectiveAmount.round()} - $transferNote'),
                              );
                              ModuleNotification.info(
                                context,
                                'Đã sao chép số tiền & nội dung nộp quỹ',
                              );
                            },
                            icon: const Icon(Icons.content_copy, size: 17),
                            label: const Text('Sao chép'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.onSurface,
                              side: const BorderSide(color: AppColors.outlineVariantSoft),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showQrFallback && qrData.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outlineVariantSoft),
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 150,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Quét bằng app MoMo nếu Deeplink không tự mở',
                              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // BƯỚC 2: Tải biên lai & ghi nhận Streak DailyYou
              const AppSectionHeader(title: 'Bước 2 — Tải biên lai & Ghi nhận Streak'),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isSubmitting ? null : _pickReceiptImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    color: _receiptImage != null
                        ? AppColors.mintContainer
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _receiptImage != null ? AppColors.mint : AppColors.outline,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_receiptImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _receiptImage!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _receiptImage != null
                                ? Icons.check_circle
                                : Icons.cloud_upload_outlined,
                            color: _receiptImage != null
                                ? AppColors.onMintContainer
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _receiptImage != null
                                  ? 'Đã chọn: $receiptFileName (chạm để đổi)'
                                  : 'Chụp / Tải ảnh biên lai giao dịch MoMo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _receiptImage != null
                                    ? AppColors.onMintContainer
                                    : AppColors.onPrimaryContainer,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cảm xúc & ghi chú ngắn kiểu DailyYou
              AppInsetCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CẢM XÚC HÔM NAY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_moods.length, (index) {
                        final active = _selectedMood == index;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: index < _moods.length - 1 ? 8 : 0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setState(() => _selectedMood = index),
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.mintContainer
                                      : AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: active
                                        ? AppColors.mint
                                        : AppColors.outlineVariantSoft,
                                    width: active ? 1.5 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(_moods[index], style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Ghi chú ngắn cho chuỗi kỷ luật...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                        prefixIcon: const Icon(
                          Icons.edit_note_rounded,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.outlineVariantSoft),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.outlineVariantSoft),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.mint, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: AppColors.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                      ),
                      if (_cameraPermanentlyDenied) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: openAppSettings,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Mở Cài đặt'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              AppPrimaryButton(
                label: _isSubmitting ? 'Đang tải biên lai...' : 'Gửi Trưởng nhóm xác nhận',
                onPressed: _isSubmitting ? null : _submitReceipt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
