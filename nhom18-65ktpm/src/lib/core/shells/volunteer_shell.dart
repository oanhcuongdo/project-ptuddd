import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/sos/data/supabase_sos_repository.dart';
import '../../features/sos/screens/active_case_screen.dart';
import '../../features/sos/widgets/sos_inbox.dart';
import '../../features/volunteer/data/supabase_volunteer_repository.dart';
import '../../features/volunteer/screens/volunteer_profile_screen.dart';
import '../../features/volunteer/volunteer_rules.dart';
import '../../features/volunteer/widgets/availability_card.dart';
import '../../models/sos_request.dart';
import '../../models/volunteer_profile.dart';
import '../../repositories/auth_repository.dart';
import '../location_service.dart';
import '../push_service.dart';
import '../theme.dart';
import '../widgets/hci_components.dart';

/// Phân hệ tình nguyện viên: UC-11 (sẵn sàng), UC-12 (nhận ca), UC-13 (hồ sơ).
class VolunteerShell extends StatefulWidget {
  const VolunteerShell({super.key});

  @override
  State<VolunteerShell> createState() => _VolunteerShellState();
}

class _ShellData {
  const _ShellData(this.profile, this.activeCase);

  final VolunteerProfile? profile;
  final SosRequest? activeCase;
}

class _VolunteerShellState extends State<VolunteerShell> {
  final _repo = SupabaseVolunteerRepository();
  final _sosRepo = SupabaseSosRepository();
  final _location = LocationService();

  late Future<_ShellData> _data = _load();
  StreamSubscription<String>? _pushSubscription;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Bấm thông báo SOS / có SOS lúc đang mở app: chuyển về tab nhận ca.
    if (PushService.takeInitialSosId() != null) _tab = 0;
    _pushSubscription = PushService.sosAlerts.listen((_) {
      if (mounted) setState(() => _tab = 0);
    });
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    super.dispose();
  }

  Future<_ShellData> _load() async {
    final profile = await _repo.myProfile();
    final activeCase = profile == null ? null : await _sosRepo.myAcceptedCase();
    if (profile != null &&
        profile.status == 'approved' &&
        profile.isAvailable) {
      unawaited(_refreshLocation());
    }
    return _ShellData(profile, activeCase);
  }

  /// TNV đang sẵn sàng: cập nhật vị trí mỗi lần mở app để bán kính nhận SOS đúng chỗ.
  Future<void> _refreshLocation() async {
    try {
      final position = await _location.current();
      await _repo.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {}
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  Future<void> _openProfileForm() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const VolunteerProfileScreen()),
    );
    if (saved == true) _reload();
  }

  Future<void> _openActiveCase(String sosId) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ActiveCaseScreen(sosId: sosId)));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ShellData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final hasProfile = data?.profile != null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tình nguyện viên'),
            actions: [
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: () => confirmAndSignOut(context),
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: _buildBody(snapshot),
          bottomNavigationBar: hasProfile
              ? NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.sos),
                      label: 'Cứu hộ',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.badge),
                      label: 'Hồ sơ',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<_ShellData> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      final error = snapshot.error;
      return _Centered(
        text: error is AppException ? error.message : 'Không tải được dữ liệu.',
        action: FilledButton(onPressed: _reload, child: const Text('Thử lại')),
      );
    }

    final data = snapshot.data!;
    final profile = data.profile;
    if (profile == null) {
      return _Centered(
        icon: Icons.volunteer_activism,
        text:
            'Bạn chưa có hồ sơ tình nguyện viên.\n'
            'Đăng ký hồ sơ để được duyệt và nhận yêu cầu cứu hộ.',
        action: FilledButton(
          onPressed: _openProfileForm,
          child: const Text('Đăng ký hồ sơ tình nguyện'),
        ),
      );
    }

    return _tab == 0
        ? _RescueTab(
            profile: profile,
            activeCase: data.activeCase,
            onChanged: _reload,
            onOpenCase: _openActiveCase,
          )
        : _ProfileTab(profile: profile, onEdit: _openProfileForm);
  }
}

class _RescueTab extends StatelessWidget {
  const _RescueTab({
    required this.profile,
    required this.activeCase,
    required this.onChanged,
    required this.onOpenCase,
  });

  final VolunteerProfile profile;
  final SosRequest? activeCase;
  final VoidCallback onChanged;
  final ValueChanged<String> onOpenCase;

  @override
  Widget build(BuildContext context) {
    final current = activeCase;
    final Widget content;
    if (current != null) {
      // Đang xử lý ca thì không hiện hộp thư để không bật Pop-up chồng lên.
      content = Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: const Icon(Icons.sos),
            title: Text('Đang xử lý ca: ${current.issueType}'),
            subtitle: const Text('Hoàn thành ca này trước khi nhận ca mới'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpenCase(current.id),
          ),
        ),
      );
    } else if (profile.status != 'approved') {
      final reason = profile.rejectionReason?.trim() ?? '';
      content = _Centered(
        icon: Icons.hourglass_top,
        text: profile.status == 'rejected' && reason.isNotEmpty
            ? '${volunteerStatusLabel(profile.status)}\nLý do: $reason'
            : volunteerStatusLabel(profile.status),
      );
    } else if (!profile.isAvailable) {
      content = const _Centered(
        icon: Icons.bedtime,
        text: 'Bật "Sẵn sàng hỗ trợ" để nhận yêu cầu SOS ở gần bạn.',
      );
    } else {
      content = SosInbox(onCaseFinished: onChanged);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: AvailabilityCard(profile: profile, onChanged: onChanged),
        ),
        Expanded(child: content),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.profile, required this.onEdit});

  final VolunteerProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final tools = profile.tools ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDeep.withValues(alpha: 0.18),
                blurRadius: 16,
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
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Hồ sơ tình nguyện viên',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  buildStatusBadge(profile.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ProfileMetricPill(
                      icon: Icons.emoji_events_rounded,
                      label: 'Ca hoàn thành',
                      value: '${profile.completedCount}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProfileMetricPill(
                      icon: Icons.radar_rounded,
                      label: 'Bán kính hỗ trợ',
                      value: '${profile.serviceRadiusKm} km',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Trạng thái hồ sơ'),
                trailing: buildStatusBadge(profile.status),
                subtitle: Text(
                  profile.status == 'rejected' &&
                          (profile.rejectionReason?.trim().isNotEmpty ?? false)
                      ? '${volunteerStatusLabel(profile.status)}\nLý do: ${profile.rejectionReason}'
                      : volunteerStatusLabel(profile.status),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.phone_rounded,
                  color: AppColors.success,
                ),
                title: const Text('Số điện thoại'),
                subtitle: Text(profile.phone),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.build_rounded,
                  color: AppColors.motoOrange,
                ),
                title: const Text('Kỹ năng'),
                subtitle: Text(profile.skills.join(', ')),
              ),
              if (tools.isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.handyman_rounded,
                    color: AppColors.navyBrand,
                  ),
                  title: const Text('Dụng cụ'),
                  subtitle: Text(tools),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (profile.status != 'banned')
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Chỉnh sửa hồ sơ'),
          ),
      ],
    );
  }
}

class _ProfileMetricPill extends StatelessWidget {
  const _ProfileMetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.motoAmber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.text, this.icon, this.action});

  final String text;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: icon ?? Icons.info_outline_rounded,
      message: text,
      action: action,
    );
  }
}
