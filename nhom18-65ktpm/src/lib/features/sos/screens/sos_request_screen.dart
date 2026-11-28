import 'package:flutter/material.dart';

import '../../../core/location_service.dart';
import '../../../core/validators.dart';
import '../../../repositories/auth_repository.dart';
import '../data/supabase_sos_repository.dart';
import '../sos_rules.dart';
import 'sos_tracking_screen.dart';

/// UC-07: rider chọn loại sự cố, kiểm tra SĐT và phát tín hiệu SOS.
class SosRequestScreen extends StatefulWidget {
  const SosRequestScreen({super.key});

  @override
  State<SosRequestScreen> createState() => _SosRequestScreenState();
}

class _SosRequestScreenState extends State<SosRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  final _repo = SupabaseSosRepository();
  final _location = LocationService();

  String? _issueType;
  bool _checking = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Đang có ca chưa xong thì mở lại màn theo dõi, không cho gửi ca thứ hai.
  Future<void> _prepare() async {
    try {
      final active = await _repo.myActiveRequest();
      if (!mounted) return;
      if (active != null) {
        _openTracking(active.id);
        return;
      }

      final profile = await AuthRepository().fetchProfile();
      if (mounted && profile != null && _phone.text.isEmpty) {
        _phone.text = profile.phone;
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _openTracking(String sosId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SosTrackingScreen(sosId: sosId)),
    );
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    if (_issueType == null) {
      setState(() => _error = 'Vui lòng chọn loại sự cố');
      return;
    }
    if (!formOk) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final position = await _location.current();
      final sos = await _repo.create(
        issueType: _issueType!,
        note: _note.text,
        contactPhone: _phone.text,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (mounted) _openTracking(sos.id);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Gửi tín hiệu SOS')),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Bạn gặp sự cố gì?',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final type in sosIssueTypes)
                            ChoiceChip(
                              label: Text(type),
                              selected: _issueType == type,
                              onSelected: _sending
                                  ? null
                                  : (_) => setState(() {
                                      _issueType = type;
                                      _error = null;
                                    }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phone,
                        enabled: !_sending,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại liên hệ',
                        ),
                        validator: validatePhone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _note,
                        enabled: !_sending,
                        maxLines: 3,
                        maxLength: sosNoteMaxLength,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú (không bắt buộc)',
                          hintText: 'VD: xe Wave đỏ, đứng cạnh cây xăng',
                        ),
                        validator: validateSosNote,
                      ),
                      Text(
                        'Vị trí GPS hiện tại sẽ được gửi tới các tiệm đang mở cửa '
                        'và tình nguyện viên đang sẵn sàng ở gần bạn.',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        onPressed: _sending ? null : _submit,
                        icon: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sos),
                        label: const Text('Phát tín hiệu cứu hộ'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
