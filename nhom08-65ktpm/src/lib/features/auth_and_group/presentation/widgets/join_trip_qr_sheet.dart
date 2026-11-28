import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../providers/trip_providers.dart';

/// Bottom sheet allowing users to scan a group QR code via [MobileScanner]
/// or enter an invite code manually to join a trip.
class JoinTripQrSheet extends ConsumerStatefulWidget {
  const JoinTripQrSheet({super.key});

  @override
  ConsumerState<JoinTripQrSheet> createState() => _JoinTripQrSheetState();
}

class _JoinTripQrSheetState extends ConsumerState<JoinTripQrSheet> {
  final _codeController = TextEditingController();
  MobileScannerController? _scannerController;
  bool _hasCameraPermission = false;
  bool _checkingPermission = true;
  bool _isProcessingScan = false;

  @override
  void initState() {
    super.initState();
    _initCameraPermission();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _initCameraPermission() async {
    try {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      if (!mounted) return;
      if (status.isGranted) {
        _scannerController = MobileScannerController();
      }
      setState(() {
        _hasCameraPermission = status.isGranted;
        _checkingPermission = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasCameraPermission = false;
        _checkingPermission = false;
      });
    }
  }

  Future<void> _submitCode(String rawCode) async {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập hoặc quét mã mời nhóm.')),
      );
      return;
    }

    setState(() => _isProcessingScan = true);
    final trip = await ref.read(tripControllerProvider.notifier).joinByCode(trimmed);
    if (!mounted) return;
    setState(() => _isProcessingScan = false);

    final controllerState = ref.read(tripControllerProvider);
    if (controllerState.hasError || trip == null) {
      final err = controllerState.error?.toString() ?? 'Không thể tham gia chuyến đi.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    Navigator.of(context).pop(trip);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã tham gia chuyến đi "${trip.title}"!')),
    );
    context.go('/trip/checklist');
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripControllerProvider);
    final isBusy = _isProcessingScan || tripState.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tham gia nhóm bằng mã QR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariantSoft),
            ),
            child: _checkingPermission
                ? const Center(child: CircularProgressIndicator())
                : (_hasCameraPermission && _scannerController != null)
                    ? MobileScanner(
                        controller: _scannerController!,
                        onDetect: (capture) {
                          if (_isProcessingScan) return;
                          for (final barcode in capture.barcodes) {
                            final raw = barcode.rawValue;
                            if (raw != null && raw.trim().isNotEmpty) {
                              _codeController.text = raw;
                              _submitCode(raw);
                              break;
                            }
                          }
                        },
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.qr_code_scanner,
                                size: 40,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Chưa có quyền Camera. Bạn có thể nhập mã mời trực tiếp bên dưới.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              TextButton(
                                onPressed: _initCameraPermission,
                                child: const Text('Cấp quyền Camera'),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Hoặc nhập mã mời (VD: TB8K4M)',
              filled: true,
              fillColor: AppColors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: isBusy ? 'Đang kiểm tra...' : 'Tham gia chuyến đi',
            onPressed: isBusy ? null : () => _submitCode(_codeController.text),
          ),
        ],
      ),
    );
  }
}
