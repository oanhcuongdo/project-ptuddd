import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../utils/momo_deeplink_helper.dart';

/// Live camera QR scanner screen for scanning MoMo Group Fund QR codes.
/// Returns the scanned QR string via [Navigator.pop] on success.
class MomoQrScannerScreen extends StatefulWidget {
  const MomoQrScannerScreen({super.key});

  @override
  State<MomoQrScannerScreen> createState() => _MomoQrScannerScreenState();
}

class _MomoQrScannerScreenState extends State<MomoQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isPermanentlyDenied = false;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    setState(() => _isCheckingPermission = true);
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (!mounted) return;
    setState(() {
      _hasPermission = status.isGranted;
      _isPermanentlyDenied = status.isPermanentlyDenied;
      _isCheckingPermission = false;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasPopped) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _hasPopped = true;
        final parsed = MoMoDeeplinkHelper.parseScannedQr(rawValue);
        Navigator.of(context).pop(parsed);
        break;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR MoMo'),
        actions: [
          if (_hasPermission) ...[
            IconButton(
              tooltip: 'Bật/Tắt đèn flash',
              icon: const Icon(Icons.flash_on_outlined),
              onPressed: () => _controller.toggleTorch(),
            ),
            IconButton(
              tooltip: 'Đổi camera',
              icon: const Icon(Icons.cameraswitch_outlined),
              onPressed: () => _controller.switchCamera(),
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isCheckingPermission) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 56,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              const Text(
                'Cần quyền truy cập Camera',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng cấp quyền camera để quét mã QR Quỹ nhóm MoMo.',
                style: TextStyle(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: _isPermanentlyDenied ? 'Mở Cài đặt' : 'Cấp quyền Camera',
                onPressed: () {
                  if (_isPermanentlyDenied) {
                    openAppSettings();
                  } else {
                    _checkCameraPermission();
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
        ),
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.momo, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 32,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Đưa mã QR Quỹ nhóm MoMo vào trong khung để quét tự động.',
              style: TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
