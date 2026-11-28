import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_inset_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../models/momo_fund_config.dart';
import '../../utils/momo_deeplink_helper.dart';
import '../../utils/momo_launcher.dart';
import '../widgets/module_notification.dart';

/// 1-Tap MoMo Payment & Fallback Copy View.
/// Displays the fund's QR code, phone number, and transfer note with 1-tap copy.
class MomoPaymentScreen extends StatelessWidget {
  const MomoPaymentScreen({
    super.key,
    required this.config,
    required this.memberName,
    this.suggestedAmount,
  });

  final MoMoFundConfig config;
  final String memberName;
  final double? suggestedAmount;

  void _copyToClipboard(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ModuleNotification.info(context, 'Đã sao chép $label: $value');
  }

  Future<void> _launchMoMo(
    BuildContext context, {
    required String link,
    required String copySummary,
  }) async {
    await MoMoLauncher.openMoMo(
      context,
      deeplink: link,
      copySummary: copySummary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final transferNote = MoMoDeeplinkHelper.buildTransferNote(
      tripId: config.tripId,
      memberName: memberName,
    );
    final effectiveLink = (config.momoFundDeeplink?.isNotEmpty == true)
        ? config.momoFundDeeplink!
        : MoMoDeeplinkHelper.buildFallbackLink(config.momoPhoneNumber);
    final qrData = (config.qrCodeUrl?.isNotEmpty == true)
        ? config.qrCodeUrl!
        : effectiveLink;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nạp tiền vào Quỹ MoMo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  config.fundName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Chủ quỹ: ${config.hostName}',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                if (suggestedAmount != null && suggestedAmount! > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.momoContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Số tiền gợi ý: ${MoMoDeeplinkHelper.formatVnd(suggestedAmount!.round())}',
                      style: const TextStyle(
                        color: AppColors.momo,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (qrData.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200,
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Chưa có mã QR. Vui lòng sao chép số điện thoại bên dưới.',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Quét mã QR bằng ứng dụng MoMo hoặc sao chép thông tin chuyển khoản bên dưới.',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CopyRow(
                  label: 'Số điện thoại MoMo',
                  value: config.momoPhoneNumber.isEmpty
                      ? 'Chưa cập nhật'
                      : config.momoPhoneNumber,
                  onCopy: config.momoPhoneNumber.isEmpty
                      ? null
                      : () => _copyToClipboard(
                            context,
                            'Số điện thoại',
                            config.momoPhoneNumber,
                          ),
                ),
                const Divider(height: 20),
                _CopyRow(
                  label: 'Nội dung chuyển khoản',
                  value: transferNote,
                  onCopy: () => _copyToClipboard(
                    context,
                    'Nội dung chuyển khoản',
                    transferNote,
                  ),
                ),
                if (effectiveLink.isNotEmpty) ...[
                  const Divider(height: 20),
                  _CopyRow(
                    label: 'Liên kết Quỹ MoMo',
                    value: effectiveLink,
                    onCopy: () => _copyToClipboard(
                      context,
                      'Liên kết MoMo',
                      effectiveLink,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: 'Mở ứng dụng MoMo',
            icon: Icons.open_in_new,
            backgroundColor: AppColors.momo,
            onPressed: () {
              final copyText = config.momoPhoneNumber.isNotEmpty
                  ? config.momoPhoneNumber
                  : transferNote;
              _launchMoMo(
                context,
                link: effectiveLink,
                copySummary: copyText,
              );
            },
          ),
          const SizedBox(height: 10),
          AppPrimaryButton(
            label: 'Sao chép SĐT & Nội dung chuyển khoản',
            onPressed: () {
              final combined =
                  'SĐT MoMo: ${config.momoPhoneNumber}\nNội dung: $transferNote';
              _copyToClipboard(context, 'thông tin chuyển khoản', combined);
            },
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            tooltip: 'Sao chép',
            icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
            onPressed: onCopy,
          ),
      ],
    );
  }
}
