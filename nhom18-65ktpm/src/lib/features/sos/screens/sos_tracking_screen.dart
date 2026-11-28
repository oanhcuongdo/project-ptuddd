import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/hci_components.dart';
import '../../../models/sos_request.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/shop_repository.dart';
import '../../../repositories/sos_repository.dart';
import '../../review/widgets/review_form.dart';
import '../data/supabase_sos_repository.dart';
import '../sos_actions.dart';
import '../sos_rules.dart';

/// UC-07 (bước 6): rider theo dõi ca SOS realtime cho tới khi có người nhận / hoàn thành.
class SosTrackingScreen extends StatefulWidget {
  const SosTrackingScreen({super.key, required this.sosId});

  final String sosId;

  @override
  State<SosTrackingScreen> createState() => _SosTrackingScreenState();
}

class _SosTrackingScreenState extends State<SosTrackingScreen> {
  final _repo = SupabaseSosRepository();
  late Stream<SosRequest?> _stream = _repo.watchById(widget.sosId);

  Future<SosContact>? _contact;
  Timer? _timeoutTimer;
  bool _checkedHelpers = false;
  bool _noNearbyHelpers = false;
  bool _timedOut = false;
  bool _cancelling = false;

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _contact = null;
      _stream = _repo.watchById(widget.sosId);
    });
  }

  void _reloadContact(String sosId) {
    setState(() {
      _contact = _repo.contact(sosId);
    });
  }

  void _ensurePendingChecks(SosRequest sos) {
    if (!_checkedHelpers) {
      _checkedHelpers = true;
      unawaited(
        _repo
            .hasNearbyHelpers(latitude: sos.latitude, longitude: sos.longitude)
            .then((hasHelpers) {
              if (mounted && !hasHelpers) {
                setState(() => _noNearbyHelpers = true);
              }
            }),
      );
    }
    if (_timeoutTimer != null) return;

    final created = sos.createdAt?.toLocal() ?? DateTime.now();
    final remaining = sosTimeout - DateTime.now().difference(created);
    if (remaining <= Duration.zero) {
      unawaited(_handleTimeout());
      return;
    }
    _timeoutTimer = Timer(remaining, () => unawaited(_handleTimeout()));
  }

  Future<void> _handleTimeout() async {
    try {
      await _repo.cancel(widget.sosId);
      if (mounted) setState(() => _timedOut = true);
    } on AppException {
      // Ca có thể vừa được tiếp nhận trước khi timeout kích hoạt.
    }
  }

  Future<void> _review(String shopId) async {
    String shopName = 'Tiệm đã hỗ trợ bạn';
    try {
      shopName = (await ShopRepository().byId(shopId))?.name ?? shopName;
    } catch (_) {
      // Không lấy được tên tiệm vẫn cho đánh giá.
    }
    if (!mounted) return;
    await showReviewSheet(context, shopId: shopId, shopName: shopName);
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy yêu cầu cứu hộ?'),
        content: const Text(
          'Các tiệm và tình nguyện viên sẽ không nhận được ca này nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy yêu cầu'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      await _repo.cancel(widget.sosId);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu cứu hộ')),
      body: SafeArea(
        child: StreamBuilder<SosRequest?>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _Message(
                icon: Icons.wifi_off,
                text: 'Mất kết nối tới máy chủ, đang không cập nhật được trạng thái ca.',
                action: FilledButton(
                  onPressed: _retry,
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
              return const _Message(
                icon: Icons.search_off,
                text: 'Không tìm thấy yêu cầu cứu hộ.',
              );
            }

            if (sos.status != 'pending') {
              _timeoutTimer?.cancel();
            }

            switch (sos.status) {
              case 'pending':
                _ensurePendingChecks(sos);
                return _Waiting(
                  cancelling: _cancelling,
                  noNearbyHelpers: _noNearbyHelpers,
                  onCancel: _cancel,
                );
              case 'accepted':
                _contact ??= _repo.contact(sos.id);
                return _Accepted(
                  contact: _contact!,
                  onRetry: () => _reloadContact(sos.id),
                );
              case 'completed':
                final shopId = sos.acceptedShopId;
                return _Message(
                  icon: Icons.check_circle,
                  text: 'Ca cứu hộ đã hoàn thành. Chúc bạn thượng lộ bình an!',
                  // UC-12 bước 8: ca do tiệm hỗ trợ thì gợi ý đánh giá (UC-08).
                  action: shopId == null
                      ? null
                      : FilledButton.icon(
                          onPressed: () => _review(shopId),
                          icon: const Icon(Icons.star),
                          label: const Text('Đánh giá dịch vụ'),
                        ),
                );
              default:
                return _Message(
                  icon: _timedOut ? Icons.timer_off : Icons.cancel_outlined,
                  text: _timedOut
                      ? 'Quá 5 phút chưa có người tiếp nhận. Yêu cầu đã tự động hủy, vui lòng gọi trực tiếp hotline khẩn cấp.'
                      : 'Bạn đã hủy yêu cầu cứu hộ này.',
                  action: _timedOut ? const _HotlineButtons() : null,
                );
            }
          },
        ),
      ),
    );
  }
}

class _Waiting extends StatefulWidget {
  const _Waiting({
    required this.cancelling,
    required this.noNearbyHelpers,
    required this.onCancel,
  });

  final bool cancelling;
  final bool noNearbyHelpers;
  final VoidCallback onCancel;

  @override
  State<_Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<_Waiting>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 176,
              height: 176,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var wave = 0; wave < 3; wave++)
                      Builder(
                        builder: (_) {
                          final t = (_pulse.value + wave / 3) % 1.0;
                          return Container(
                            width: 68 + 106 * t,
                            height: 68 + 106 * t,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(alpha: 0.24 * (1 - t)),
                              border: Border.all(
                                color: color.withValues(alpha: 0.42 * (1 - t)),
                                width: 1.5,
                              ),
                            ),
                          );
                        },
                      ),
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.sosRedDark, AppColors.sosRed],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.38),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sos_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang chờ cứu hộ...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.noNearbyHelpers
                  ? 'Hiện không có tiệm sửa xe hoặc tình nguyện viên nào hoạt động gần bạn. Vui lòng gọi trực tiếp hotline cứu hộ khẩn cấp.'
                  : 'Đã gửi tín hiệu tới các tiệm và tình nguyện viên ở gần. '
                      'Tự động hủy sau 5 phút nếu chưa có người tiếp nhận.',
              textAlign: TextAlign.center,
            ),
            if (widget.noNearbyHelpers) ...[
              const SizedBox(height: 16),
              const _HotlineButtons(),
            ],
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: widget.cancelling ? null : widget.onCancel,
              child: const Text('Hủy yêu cầu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotlineButtons extends StatelessWidget {
  const _HotlineButtons();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final item in emergencyHotlines)
          ActionChip(
            avatar: const Icon(Icons.call, size: 18),
            label: Text(item.label),
            onPressed: () => launchPhoneCall(context, item.phone),
          ),
      ],
    );
  }
}

class _Accepted extends StatelessWidget {
  const _Accepted({required this.contact, required this.onRetry});

  final Future<SosContact> contact;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<SosContact>(
          future: contact,
          builder: (context, snapshot) {
            final info = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.handshake,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Đã có người tiếp nhận!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Người hỗ trợ đang di chuyển tới vị trí của bạn.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const CircularProgressIndicator()
                else if (info == null) ...[
                  Text(
                    snapshot.error?.toString() ??
                        'Không tải được thông tin người hỗ trợ.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Thử lại'),
                  ),
                ] else
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(info.name),
                      subtitle: Text(info.phone),
                      trailing: IconButton.filled(
                        tooltip: 'Gọi ngay',
                        onPressed: () => launchPhoneCall(context, info.phone),
                        icon: const Icon(Icons.call),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final accent = icon == Icons.check_circle
        ? AppColors.success
        : (icon == Icons.wifi_off || icon == Icons.timer_off)
            ? AppColors.warning
            : AppColors.primary;
    return EmptyStateCard(
      icon: icon,
      message: text,
      accentColor: accent,
      action: action,
    );
  }
}
