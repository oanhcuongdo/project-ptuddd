import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../repositories/auth_repository.dart';
import '../data/supabase_sos_repository.dart';
import '../screens/active_case_screen.dart';
import '../sos_rules.dart';

/// UC-12: hộp thư SOS của người nhận (TNV hoặc chủ tiệm).
/// Ca mới hiện Pop-up khẩn cấp; ca bị người khác nhận / bị hủy tự biến mất.
/// Chủ tiệm (Hiếu) chỉ cần đặt widget này vào màn hình của mình.
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
  List<NearbySos> _items = const [];
  String? _error;
  bool _loaded = false;
  bool _dialogOpen = false;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _currentIds.dispose();
    super.dispose();
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
    if (_dialogOpen || _accepting) return;
    final fresh = _visible.where((e) => !_alerted.contains(e.request.id));
    if (fresh.isEmpty) return;

    final item = fresh.first;
    _alerted.addAll(_visible.map((e) => e.request.id));
    _dialogOpen = true;
    unawaited(HapticFeedback.heavyImpact());
    unawaited(SystemSound.play(SystemSoundType.alert));

    final decision = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SosAlertDialog(item: item, currentIds: _currentIds),
    );
    _dialogOpen = false;
    if (!mounted) return;

    if (decision == true) {
      await _accept(item);
    } else if (decision == false) {
      setState(() => _rejected.add(item.request.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ca cứu hộ này đã được người khác tiếp nhận hoặc đã bị hủy',
          ),
        ),
      );
    }
  }

  List<NearbySos> get _visible =>
      _items.where((e) => !_rejected.contains(e.request.id)).toList();

  Future<void> _accept(NearbySos item) async {
    if (_accepting) return;
    setState(() => _accepting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final sos = await _repo.accept(
        sosId: item.request.id,
        shopId: item.shopId,
        volunteerId: item.volunteerId,
      );
      await navigator.push(
        MaterialPageRoute(builder: (_) => ActiveCaseScreen(sosId: sos.id)),
      );
      widget.onCaseFinished?.call();
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sos, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sos.issueType,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(formatDistance(item.distanceM)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${formatAgo(sos.createdAt?.toLocal())} · ${sos.contactPhone}',
              style: theme.textTheme.bodySmall,
            ),
            if (note.isNotEmpty) ...[const SizedBox(height: 8), Text(note)],
            const SizedBox(height: 12),
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

/// Pop-up khẩn cấp. Trả true = tiếp nhận, false = từ chối,
/// null = ca không còn chờ (người khác đã nhận / rider hủy) nên tự đóng.
class _SosAlertDialog extends StatefulWidget {
  const _SosAlertDialog({required this.item, required this.currentIds});

  final NearbySos item;
  final ValueNotifier<Set<String>> currentIds;

  @override
  State<_SosAlertDialog> createState() => _SosAlertDialogState();
}

class _SosAlertDialogState extends State<_SosAlertDialog> {
  @override
  void initState() {
    super.initState();
    widget.currentIds.addListener(_onIdsChanged);
  }

  @override
  void dispose() {
    widget.currentIds.removeListener(_onIdsChanged);
    super.dispose();
  }

  bool _closed = false;

  void _close(bool? decision) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(decision);
  }

  void _onIdsChanged() {
    if (!widget.currentIds.value.contains(widget.item.request.id)) _close(null);
  }

  @override
  Widget build(BuildContext context) {
    final sos = widget.item.request;
    final note = sos.note ?? '';

    return AlertDialog(
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
          _SosMap(latitude: sos.latitude, longitude: sos.longitude),
          const SizedBox(height: 12),
          Text('Sự cố: ${sos.issueType}'),
          Text('Cách bạn: ${formatDistance(widget.item.distanceM)}'),
          Text('SĐT: ${sos.contactPhone}'),
          if (note.isNotEmpty) Text('Ghi chú: $note'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _close(false),
          child: const Text('Từ chối'),
        ),
        FilledButton(
          onPressed: () => _close(true),
          child: const Text('Tiếp nhận'),
        ),
      ],
    );
  }
}

/// Vị trí sự cố trong Pop-up (lite mode: ảnh tĩnh, nhẹ, không cần thao tác).
class _SosMap extends StatelessWidget {
  const _SosMap({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 160,
        width: double.maxFinite,
        child: GoogleMap(
          liteModeEnabled: true,
          initialCameraPosition: CameraPosition(target: point, zoom: 15),
          markers: {Marker(markerId: const MarkerId('sos'), position: point)},
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
