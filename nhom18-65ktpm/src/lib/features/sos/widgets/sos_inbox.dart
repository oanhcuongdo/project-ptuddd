import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/hci_components.dart';
import '../../../models/sos_request.dart';
import '../../../repositories/auth_repository.dart';
import '../../map/location_service.dart' as map_loc;
import '../../navigation/navigation_helper.dart';
import '../data/supabase_sos_repository.dart';
import '../screens/active_case_screen.dart';
import '../sos_rules.dart';

enum _AlertDecision { accept, reject, dismiss, gone }

/// UC-12: hộp thư SOS của người nhận (TNV hoặc chủ tiệm).
/// Tự phát hiện ca đang xử lý (`accepted`), bật Pop-up khẩn cấp cho ca mới
/// và tự thu nhỏ sau 60 giây (UC-12 A2).
class SosInbox extends StatefulWidget {
  const SosInbox({super.key, this.onCaseFinished});

  /// Gọi khi quay về từ màn ca đang xử lý (để màn cha tải lại trạng thái).
  final VoidCallback? onCaseFinished;

  @override
  State<SosInbox> createState() => _SosInboxState();
}

class _SosInboxState extends State<SosInbox> {
  final _repo = SupabaseSosRepository();
  final _currentIds = ValueNotifier<Set<String>>({});

  /// Ca đã bật Pop-up (không bật lại) và ca đã bấm Từ chối (ẩn khỏi danh sách).
  final _alerted = <String>{};
  final _rejected = <String>{};

  StreamSubscription<List<NearbySos>>? _subscription;
  SosRequest? _activeCase;
  List<NearbySos> _items = const [];
  String? _error;
  bool _loaded = false;
  bool _dialogOpen = false;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _currentIds.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final current = await _repo.myAcceptedCase();
      if (!mounted) return;
      if (current != null) {
        setState(() {
          _activeCase = current;
          _loaded = true;
          _error = null;
        });
        return;
      }
      setState(() => _activeCase = null);
    } catch (_) {
      // Nếu lỗi kiểm tra ca đang xử lý, tiếp tục nghe hộp thư như bình thường.
    }
    _listen();
  }

  void _listen() {
    _subscription?.cancel();
    _subscription = _repo.watchNearbyPending().listen(
      (items) {
        if (!mounted) return;
        _currentIds.value = items.map((e) => e.request.id).toSet();
        setState(() {
          _items = items;
          _loaded = true;
          _error = null;
        });
        _alertNewCase();
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _loaded = true;
          _error = e is AppException
              ? e.message
              : 'Không tải được yêu cầu SOS.';
        });
      },
    );
  }

  Future<void> _alertNewCase() async {
    if (_dialogOpen || _accepting || _activeCase != null) return;
    final fresh = _visible.where((e) => !_alerted.contains(e.request.id));
    if (fresh.isEmpty) return;

    final item = fresh.first;
    _alerted.add(item.request.id);
    _dialogOpen = true;
    unawaited(HapticFeedback.heavyImpact());
    unawaited(SystemSound.play(SystemSoundType.alert));

    final decision = await showDialog<_AlertDecision>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SosAlertDialog(item: item, currentIds: _currentIds),
    );
    _dialogOpen = false;
    if (!mounted) return;

    switch (decision) {
      case _AlertDecision.accept:
        await _accept(item);
      case _AlertDecision.reject:
        setState(() => _rejected.add(item.request.id));
        unawaited(_alertNewCase());
      case _AlertDecision.gone:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ca cứu hộ đã được người khác tiếp nhận hoặc đã bị hủy',
            ),
          ),
        );
        unawaited(_alertNewCase());
      case _AlertDecision.dismiss:
      case null:
        unawaited(_alertNewCase());
    }
  }

  List<NearbySos> get _visible =>
      _items.where((e) => !_rejected.contains(e.request.id)).toList();

  Future<void> _openActiveCase(String sosId) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ActiveCaseScreen(sosId: sosId)));
    if (!mounted) return;
    widget.onCaseFinished?.call();
    await _init();
  }

  Future<void> _accept(NearbySos item) async {
    if (_accepting) return;
    setState(() => _accepting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final sos = await _repo.accept(
        sosId: item.request.id,
        shopId: item.shopId,
        volunteerId: item.volunteerId,
      );
      if (!mounted) return;
      await _openActiveCase(sos.id);
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      // Ca đã mất hiệu lực: tải lại để ca biến khỏi danh sách ngay.
      _listen();
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());

    final active = _activeCase;
    if (active != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: const Icon(Icons.sos),
            title: Text('Đang xử lý ca: ${active.issueType}'),
            subtitle: const Text('Hoàn thành ca này trước khi nhận ca mới'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openActiveCase(active.id),
          ),
        ),
      );
    }

    final error = _error;
    if (error != null && _items.isEmpty) {
      return _Empty(
        icon: Icons.wifi_off,
        text: error,
        action: FilledButton(onPressed: _listen, child: const Text('Thử lại')),
      );
    }

    final items = _visible;
    if (items.isEmpty) {
      return const _Empty(
        icon: Icons.notifications_none,
        text:
            'Chưa có yêu cầu SOS nào gần bạn.\n'
            'Ứng dụng sẽ báo ngay khi có người cần hỗ trợ.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _SosCard(
          item: item,
          busy: _accepting,
          onAccept: () => _accept(item),
          onReject: () => setState(() => _rejected.add(item.request.id)),
        );
      },
    );
  }
}

class _SosCard extends StatelessWidget {
  const _SosCard({
    required this.item,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final NearbySos item;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final sos = item.request;
    final note = sos.note ?? '';
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.sosRed, width: 4)),
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sos_rounded,
                    color: AppColors.sosRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sos.issueType,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    formatDistance(item.distanceM),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyBrand,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${formatAgo(sos.createdAt?.toLocal())} · SĐT: ${sos.contactPhone}',
              style: theme.textTheme.bodySmall,
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(note, style: theme.textTheme.bodyMedium),
              ),
            ],
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => NavigationHelper.openExternalGoogleMaps(
                  destinationLat: sos.latitude,
                  destinationLng: sos.longitude,
                  context: context,
                ),
                icon: const Icon(Icons.map_outlined, size: 17),
                label: const Text('Xem vị trí sự cố'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sosRed,
                    ),
                    onPressed: busy ? null : onAccept,
                    child: const Text('Tiếp nhận'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pop-up khẩn cấp: phân biệt Tiếp nhận / Từ chối / Tự thu nhỏ 60s / Hết hiệu lực.
class _SosAlertDialog extends StatefulWidget {
  const _SosAlertDialog({required this.item, required this.currentIds});

  final NearbySos item;
  final ValueNotifier<Set<String>> currentIds;

  @override
  State<_SosAlertDialog> createState() => _SosAlertDialogState();
}

class _SosAlertDialogState extends State<_SosAlertDialog> {
  Timer? _autoDismiss;
  bool _closed = false;
  String? _address;

  @override
  void initState() {
    super.initState();
    widget.currentIds.addListener(_onIdsChanged);
    _autoDismiss = Timer(
      sosPopupAutoDismiss,
      () => _close(_AlertDecision.dismiss),
    );
    unawaited(_resolveAddress());
  }

  Future<void> _resolveAddress() async {
    final sos = widget.item.request;
    final addr = await map_loc.LocationService.getAddressFromCoordinates(
      sos.latitude,
      sos.longitude,
    );
    if (mounted) setState(() => _address = addr);
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    widget.currentIds.removeListener(_onIdsChanged);
    super.dispose();
  }

  void _close(_AlertDecision decision) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(decision);
  }

  void _onIdsChanged() {
    if (!widget.currentIds.value.contains(widget.item.request.id)) {
      _close(_AlertDecision.gone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sos = widget.item.request;
    final note = sos.note ?? '';
    final locationLabel =
        _address ??
        '${sos.latitude.toStringAsFixed(5)}, ${sos.longitude.toStringAsFixed(5)}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(_AlertDecision.dismiss);
      },
      child: AlertDialog(
        icon: Icon(
          Icons.sos,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Yêu cầu cứu hộ khẩn cấp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sự cố: ${sos.issueType}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('Cách bạn: ${formatDistance(widget.item.distanceM)}'),
            const SizedBox(height: 4),
            Text('Vị trí: $locationLabel'),
            const SizedBox(height: 4),
            Text('SĐT: ${sos.contactPhone}'),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Ghi chú: $note'),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => NavigationHelper.openExternalGoogleMaps(
                destinationLat: sos.latitude,
                destinationLng: sos.longitude,
                context: context,
              ),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Xem vị trí trên bản đồ'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _close(_AlertDecision.reject),
            child: const Text('Từ chối'),
          ),
          FilledButton(
            onPressed: () => _close(_AlertDecision.accept),
            child: const Text('Tiếp nhận'),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: icon,
      message: text,
      accentColor: icon == Icons.wifi_off ? AppColors.warning : AppColors.primary,
      action: action,
    );
  }
}
