import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../providers/momo_fund_provider.dart';
import '../utils/momo_deeplink_helper.dart';
import 'screens/momo_qr_scanner_screen.dart';
import 'widgets/module_provider_scope.dart';

/// Modal Sheet Thiết lập Kế hoạch & Liên kết Quỹ nhóm MoMo (Dành cho Trưởng nhóm).
class SetupMomoSheet extends StatelessWidget {
  const SetupMomoSheet({
    super.key,
    required this.initialFundName,
    this.tripId = 'trip_demo_01',
    this.hostUserId = 'host_01',
    this.hostName = 'Trưởng nhóm',
    this.targetTotalAmount = 8450000,
    this.initialPhoneNumber = '',
    this.initialFundLink = '',
  });

  final String initialFundName;
  final String tripId;
  final String hostUserId;
  final String hostName;
  final double targetTotalAmount;
  final String initialPhoneNumber;
  final String initialFundLink;

  @override
  Widget build(BuildContext context) {
    return ModuleProviderScope(
      child: _SetupMomoContent(
        initialFundName: initialFundName,
        tripId: tripId,
        hostUserId: hostUserId,
        hostName: hostName,
        targetTotalAmount: targetTotalAmount,
        initialPhoneNumber: initialPhoneNumber,
        initialFundLink: initialFundLink,
      ),
    );
  }
}

class _SetupMomoContent extends ConsumerStatefulWidget {
  const _SetupMomoContent({
    required this.initialFundName,
    required this.tripId,
    required this.hostUserId,
    required this.hostName,
    required this.targetTotalAmount,
    required this.initialPhoneNumber,
    required this.initialFundLink,
  });

  final String initialFundName;
  final String tripId;
  final String hostUserId;
  final String hostName;
  final double targetTotalAmount;
  final String initialPhoneNumber;
  final String initialFundLink;

  @override
  ConsumerState<_SetupMomoContent> createState() => _SetupMomoContentState();
}

class _SetupMomoContentState extends ConsumerState<_SetupMomoContent> {
  int _cycleMode = 1; // 0: Ngày | 1: Tuần | 2: Tháng
  late final TextEditingController _fundNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _fundLinkCtrl;
  String? _scannedQrPayload;
  MoMoQrParseResult? _parsedQrResult;
  String? _errorMessage;
  bool _isSaving = false;
  bool _isAnalyzingImage = false;

  @override
  void initState() {
    super.initState();
    _fundNameCtrl = TextEditingController(text: widget.initialFundName);
    _phoneCtrl = TextEditingController(text: widget.initialPhoneNumber);
    _fundLinkCtrl = TextEditingController(text: widget.initialFundLink);
  }

  @override
  void dispose() {
    _fundNameCtrl.dispose();
    _phoneCtrl.dispose();
    _fundLinkCtrl.dispose();
    super.dispose();
  }

  void _applyQrPayload(String rawPayload) {
    final parsed = MoMoDeeplinkHelper.parseMoMoQr(rawPayload);
    setState(() {
      _scannedQrPayload = parsed.rawPayload;
      _parsedQrResult = parsed;
      _errorMessage = null;
      if (parsed.phoneNumber != null && parsed.phoneNumber!.isNotEmpty) {
        _phoneCtrl.text = parsed.phoneNumber!;
      }
      if (parsed.deeplink != null && parsed.deeplink!.isNotEmpty) {
        _fundLinkCtrl.text = parsed.deeplink!;
      }
    });
  }

  Future<void> _scanQrCode() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const MomoQrScannerScreen()),
    );
    if (result != null && result.isNotEmpty && mounted) {
      _applyQrPayload(result);
    }
  }

  Future<void> _uploadQrImage() async {
    if (_isAnalyzingImage) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    setState(() {
      _isAnalyzingImage = true;
      _errorMessage = null;
    });

    final controller = MobileScannerController();
    try {
      final capture = await controller.analyzeImage(picked.path);
      String? decoded;
      if (capture != null) {
        for (final barcode in capture.barcodes) {
          final val = barcode.rawValue?.trim();
          if (val != null && val.isNotEmpty) {
            decoded = val;
            break;
          }
        }
      }

      if (!mounted) return;
      if (decoded != null) {
        _applyQrPayload(decoded);
      } else {
        setState(() {
          _errorMessage = 'Không tìm thấy mã QR MoMo hợp lệ trong ảnh đã chọn.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể đọc ảnh QR: $e';
        });
      }
    } finally {
      await controller.dispose();
      if (mounted) {
        setState(() => _isAnalyzingImage = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (_isSaving) return;
    final fundName = _fundNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final link = _fundLinkCtrl.text.trim();

    if (fundName.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập tên Quỹ nhóm MoMo.');
      return;
    }

    if (phone.isNotEmpty && !MoMoDeeplinkHelper.isValidPhoneNumber(phone)) {
      setState(() => _errorMessage = 'Số điện thoại MoMo không hợp lệ (VD: 0912345678).');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ref.read(momoFundProvider(widget.tripId).notifier).saveFundConfig(
            fundName: fundName,
            hostUserId: widget.hostUserId,
            hostName: widget.hostName,
            momoPhoneNumber: phone,
            momoFundDeeplink: link.isEmpty ? null : link,
            qrCodeUrl: _scannedQrPayload ?? (link.isEmpty ? null : link),
            targetTotalAmount: widget.targetTotalAmount,
          );
      if (mounted) {
        Navigator.pop(context, fundName);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Lỗi lưu cấu hình MoMo: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep autoDispose momoFundProvider alive while the setup sheet is open.
    ref.watch(momoFundProvider(widget.tripId));
    final (cycleLabel, perMemberAmount) = switch (_cycleMode) {
      0 => ('ngày', 30200),
      1 => ('tuần', 212000),
      _ => ('tháng', 845000),
    };

    final hasQr = (_scannedQrPayload?.isNotEmpty == true) ||
        _fundLinkCtrl.text.trim().isNotEmpty;

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Hủy', style: TextStyle(color: AppColors.onPrimaryContainer)),
                  ),
                  const Expanded(
                    child: Text(
                      'Thiết lập Quỹ MoMo',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _isSaving ? null : _saveConfig,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Lưu',
                            style: TextStyle(
                              color: AppColors.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Khối 1: Saving Plan Generator
              const AppSectionHeader(title: '1. Kế hoạch chia kỳ đóng quỹ'),
              AppSegmentedControl(
                segments: const ['Theo ngày', 'Theo tuần', 'Theo tháng'],
                selectedIndex: _cycleMode,
                onChanged: (i) => setState(() => _cycleMode = i),
              ),
              const SizedBox(height: 10),
              AppInsetCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mức đóng đề xuất / người',
                            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tổng 8.450.000đ • 4 thành viên',
                            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${MoMoDeeplinkHelper.formatVnd(perMemberAmount)}/$cycleLabel',
                      style: AppTheme.monoAmount(fontSize: 16, color: AppColors.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Khối 2: Liên kết Quỹ nhóm MoMo
              const AppSectionHeader(title: '2. Liên kết Quỹ nhóm MoMo'),
              AppInsetCard(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _fundNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tên Quỹ nhóm MoMo',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Divider(indent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại MoMo chủ quỹ',
                          hintText: '09xx xxx xxx',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Divider(indent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _fundLinkCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Đường dẫn (Link) Quỹ nhóm MoMo',
                          hintText: 'https://me.momo.vn/...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scanQrCode,
                      icon: const Icon(Icons.qr_code_scanner, size: 18, color: AppColors.momo),
                      label: const Text('Quét QR MoMo', style: TextStyle(color: AppColors.onSurface)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainer,
                        side: const BorderSide(color: AppColors.outlineVariantSoft),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzingImage ? null : _uploadQrImage,
                      icon: _isAnalyzingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: Text(
                        _isAnalyzingImage ? 'Đang đọc...' : 'Tải ảnh QR',
                        style: const TextStyle(color: AppColors.onSurface),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainer,
                        side: const BorderSide(color: AppColors.outlineVariantSoft),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              if (hasQr) ...[
                const SizedBox(height: 12),
                AppInsetCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2, size: 44, color: AppColors.momo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đã nhận diện mã QR Quỹ nhóm MoMo',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _parsedQrResult?.displaySummary ??
                                  (_scannedQrPayload ?? _fundLinkCtrl.text.trim()),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.amberContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.amber),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onAmberContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              AppPrimaryButton(
                label: _isSaving ? 'Đang lưu...' : 'Lưu cấu hình & Liên kết MoMo',
                backgroundColor: AppColors.momo,
                onPressed: _isSaving ? null : _saveConfig,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
