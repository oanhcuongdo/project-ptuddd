import 'package:flutter/material.dart';

import '../../../core/location_service.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/hci_components.dart';
import '../../../models/sos_request.dart';
import '../../../repositories/auth_repository.dart';
import '../../navigation/screens/navigation_screen.dart';
import '../data/supabase_sos_repository.dart';
import '../sos_actions.dart';
import '../sos_rules.dart';

/// UC-12 (bước 6–7): ca cứu hộ đang xử lý của chủ tiệm / TNV.
/// Pop true khi đã bấm hoàn thành.
class ActiveCaseScreen extends StatefulWidget {
  const ActiveCaseScreen({super.key, required this.sosId});

  final String sosId;

  @override
  State<ActiveCaseScreen> createState() => _ActiveCaseScreenState();
}

class _ActiveCaseScreenState extends State<ActiveCaseScreen> {
  final _repo = SupabaseSosRepository();
  late Stream<SosRequest?> _stream = _repo.watchById(widget.sosId);
  bool _completing = false;

  Future<void> _complete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành ca cứu hộ?'),
        content: const Text('Chỉ xác nhận khi đã hỗ trợ xong cho khách hàng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Chưa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _completing = true);
    try {
      await _repo.complete(widget.sosId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã hoàn thành ca cứu hộ. Cảm ơn bạn!')),
      );
      navigator.pop(true);
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ca cứu hộ đang xử lý')),
      body: SafeArea(
        child: StreamBuilder<SosRequest?>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _Info(
                text: 'Mất kết nối tới máy chủ.',
                action: FilledButton(
                  onPressed: () =>
                      setState(() => _stream = _repo.watchById(widget.sosId)),
                  child: const Text('Thử lại'),
                ),
              );
            }
            if (!snapshot.hasData &&
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final sos = snapshot.data;
            if (sos == null) {
              return const _Info(text: 'Không tìm thấy ca cứu hộ.');
            }
            if (sos.status == 'completed') {
              return const _Info(text: 'Ca cứu hộ đã hoàn thành.');
            }
            if (sos.status != 'accepted') {
              return const _Info(
                text: 'Ca cứu hộ này không còn ở trạng thái đang xử lý.',
              );
            }
            return _Detail(
              sos: sos,
              completing: _completing,
              onComplete: _complete,
            );
          },
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.sos,
    required this.completing,
    required this.onComplete,
  });

  final SosRequest sos;
  final bool completing;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final note = sos.note ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.sosRedDark, AppColors.sosRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.sosRed.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sos_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'ĐANG XỬ LÝ CỨU HỘ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Gửi ${formatAgo(sos.createdAt?.toLocal())}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                sos.issueType,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Ghi chú: $note',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.phone_rounded, color: AppColors.success),
            ),
            title: const Text(
              'SĐT khách hàng',
              style: TextStyle(fontSize: 12.5, color: AppColors.inkSecondary),
            ),
            subtitle: Text(
              sos.contactPhone,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.inkPrimary,
              ),
            ),
            trailing: IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: AppColors.success),
              tooltip: 'Gọi ngay',
              onPressed: () => launchPhoneCall(context, sos.contactPhone),
              icon: const Icon(Icons.call_rounded, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          onPressed: () async {
            try {
              final pos = await LocationService().current();
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NavigationScreen(
                    originLat: pos.latitude,
                    originLng: pos.longitude,
                    destinationLat: sos.latitude,
                    destinationLng: sos.longitude,
                    destinationTitle: 'Sự cố: ${sos.issueType}',
                    destinationAddress: sos.note,
                  ),
                ),
              );
            } catch (_) {
              if (context.mounted) {
                await launchDirections(context, sos.latitude, sos.longitude);
              }
            }
          },
          icon: const Icon(Icons.directions_rounded),
          label: const Text('Chỉ đường tới vị trí sự cố'),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: completing ? null : onComplete,
          icon: completing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.task_alt_rounded),
          label: const Text('Hoàn thành ca cứu hộ'),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: Icons.info_outline_rounded,
      message: text,
      action: action,
    );
  }
}
