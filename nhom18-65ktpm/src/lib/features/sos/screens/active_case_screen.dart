import 'package:flutter/material.dart';

import '../../../models/sos_request.dart';
import '../../../repositories/auth_repository.dart';
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
    final theme = Theme.of(context);
    final note = sos.note ?? '';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(sos.issueType, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Gửi ${formatAgo(sos.createdAt?.toLocal())}'),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Ghi chú: $note'),
        ],
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('SĐT khách hàng'),
            subtitle: Text(sos.contactPhone),
            trailing: IconButton.filled(
              tooltip: 'Gọi ngay',
              onPressed: () => launchPhoneCall(context, sos.contactPhone),
              icon: const Icon(Icons.call),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () =>
              launchDirections(context, sos.latitude, sos.longitude),
          icon: const Icon(Icons.directions),
          label: const Text('Chỉ đường tới vị trí sự cố'),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: completing ? null : onComplete,
          icon: completing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.task_alt),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
