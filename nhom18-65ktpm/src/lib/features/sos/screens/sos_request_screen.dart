import 'package:flutter/material.dart';

import '../../../core/location_service.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/hci_components.dart';
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

  IconData _issueIcon(String type) => switch (type) {
    'Hết xăng' => Icons.local_gas_station_rounded,
    'Thủng lốp' => Icons.tire_repair_rounded,
    'Hỏng động cơ' => Icons.build_circle_rounded,
    _ => Icons.help_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gửi tín hiệu SOS')),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Banner trấn an & giải thích cơ chế gửi GPS (Nielsen #1)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.sosRedDark, AppColors.sosRed],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sosRed.withValues(alpha: 0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.sos_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cứu hộ xe máy khẩn cấp',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Vị trí GPS sẽ tự động gửi tới tiệm đang mở & tình nguyện viên gần nhất.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nhóm 1: Nhận diện loại sự cố bằng thẻ biểu tượng trực quan (Hick's Law)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                icon: Icons.warning_amber_rounded,
                                title: 'Bạn gặp sự cố gì?',
                                color: AppColors.sosRed,
                              ),
                              const SizedBox(height: 12),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 2.35,
                                children: [
                                  for (final type in sosIssueTypes)
                                    _IssueOptionCard(
                                      label: type,
                                      icon: _issueIcon(type),
                                      selected: _issueType == type,
                                      enabled: !_sending,
                                      onTap: () => setState(() {
                                        _issueType = type;
                                        _error = null;
                                      }),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Nhóm 2: Thông tin liên hệ & mô tả nhận diện nhanh
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                icon: Icons.contact_phone_rounded,
                                title: 'Thông tin liên hệ',
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phone,
                                enabled: !_sending,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Số điện thoại liên hệ',
                                  prefixIcon: Icon(Icons.phone_outlined),
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
                                  hintText:
                                      'VD: xe Wave đỏ, đứng cạnh cây xăng',
                                  prefixIcon: Icon(Icons.notes_rounded),
                                ),
                                validator: validateSosNote,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const FeedbackBanner(
                        message:
                            'Vị trí GPS hiện tại sẽ được gửi tới các tiệm đang mở cửa '
                            'và tình nguyện viên đang sẵn sàng ở gần bạn.',
                        tone: FeedbackTone.info,
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        FeedbackBanner(
                          message: _error!,
                          tone: FeedbackTone.error,
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sosRed,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                        ),
                        onPressed: _sending ? null : _submit,
                        icon: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sos_rounded),
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

class _IssueOptionCard extends StatelessWidget {
  const _IssueOptionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.dangerBg : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.sosRed : AppColors.border,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.sosRed : AppColors.inkSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? AppColors.sosRedDark
                        : AppColors.inkPrimary,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.sosRed,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
