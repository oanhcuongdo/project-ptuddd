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

class _MomoQrScannerScreenState extends State<MomoQrScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;

  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isRequestingPermission = false;
  bool _isPermanentlyDenied = false;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  MobileScannerController _ensureController() {
    return _controller ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_hasPermission &&
        !_isRequestingPermission) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_hasPermission && !_isRequestingPermission) {
          _syncPermissionStatusSilently();
        }
      });
    }
  }

  Future<void> _syncPermissionStatusSilently({bool notifyIfDenied = false}) async {
    final status = await Permission.camera.status;
    if (!mounted) return;
    final granted = status.isGranted;
    if (granted) {
      _ensureController();
    }
    setState(() {
      _hasPermission = granted;
      if (status.isPermanentlyDenied || status.isRestricted) {
        _isPermanentlyDenied = true;
      }
      _isCheckingPermission = false;
    });
    if (!granted && notifyIfDenied && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Quyền camera vẫn chưa được bật. Vui lòng cấp quyền trong Cài đặt ứng dụng.',
            ),
          ),
        );
    }
  }

  Future<void> _requestCameraPermission({bool fromUserTap = false}) async {
    if (_isRequestingPermission) return;
    _isRequestingPermission = true;
    if (!_hasPermission && !fromUserTap && mounted) {
      setState(() => _isCheckingPermission = true);
    }

    try {
      var status = await Permission.camera.status;
      final beforeTapWasDenied = status.isDenied;
      if (!status.isGranted &&
          !status.isPermanentlyDenied &&
          !status.isRestricted) {
        status = await Permission.camera.request();
      }

      if (!mounted) return;
      final granted = status.isGranted;
      final permDenied = status.isPermanentlyDenied || status.isRestricted;
      if (granted) {
        _ensureController();
      }
      setState(() {
        _hasPermission = granted;
        _isPermanentlyDenied = _isPermanentlyDenied || permDenied;
        _isCheckingPermission = false;
      });

      if (!granted && fromUserTap && (permDenied || beforeTapWasDenied)) {
        // Android suppresses repeat permission dialogs after denial; guide user straight to Settings.
        await openAppSettings();
      }
    } finally {
      _isRequestingPermission = false;
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR MoMo'),
        actions: [
          if (_hasPermission && _controller != null) ...[
            IconButton(
              tooltip: 'Bật/Tắt đèn flash',
              icon: const Icon(Icons.flash_on_outlined, color: AppColors.primary),
              onPressed: () => _controller?.toggleTorch(),
            ),
            IconButton(
              tooltip: 'Đổi camera',
              icon: const Icon(Icons.cameraswitch_outlined, color: AppColors.primary),
              onPressed: () => _controller?.switchCamera(),
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
                    _requestCameraPermission(fromUserTap: true);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    _syncPermissionStatusSilently(notifyIfDenied: true),
                child: const Text('Đã cấp quyền? Kiểm tra lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _ensureController(),
          onDetect: _onDetect,
          errorBuilder: (_, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam_off_outlined,
                    size: 48,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Không thể khởi động Camera',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error.errorDetails?.message ??
                        'Vui lòng thử khởi động lại camera.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    label: 'Thử lại',
                    onPressed: () => _ensureController().start(),
                  ),
                ],
              ),
            ),
          ),
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
