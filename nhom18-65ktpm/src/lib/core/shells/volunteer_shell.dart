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
    unawaited(PushService.register());
    // Bấm thông báo SOS / có SOS lúc đang mở app: chuyển về tab nhận ca.
    PushService.takeInitialSosId();
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

  void _reload() => setState(() => _data = _load());

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
                onPressed: () => AuthRepository().signOut(),
                icon: const Icon(Icons.logout),
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
      content = _Centered(
        icon: Icons.hourglass_top,
        text: volunteerStatusLabel(
          profile.status,
          rejectionReason: profile.rejectionReason,
        ),
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
        ListTile(
          leading: const Icon(Icons.verified_user),
          title: const Text('Trạng thái hồ sơ'),
          subtitle: Text(
            volunteerStatusLabel(
              profile.status,
              rejectionReason: profile.rejectionReason,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.phone),
          title: const Text('Số điện thoại'),
          subtitle: Text(profile.phone),
        ),
        ListTile(
          leading: const Icon(Icons.build),
          title: const Text('Kỹ năng'),
          subtitle: Text(profile.skills.join(', ')),
        ),
        if (tools.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.handyman),
            title: const Text('Dụng cụ'),
            subtitle: Text(tools),
          ),
        ListTile(
          leading: const Icon(Icons.radar),
          title: const Text('Bán kính hỗ trợ'),
          subtitle: Text('${profile.serviceRadiusKm} km'),
        ),
        ListTile(
          leading: const Icon(Icons.emoji_events),
          title: const Text('Ca đã hoàn thành'),
          subtitle: Text('${profile.completedCount}'),
        ),
        const SizedBox(height: 12),
        if (profile.status != 'banned')
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Chỉnh sửa hồ sơ'),
          ),
      ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 56),
              const SizedBox(height: 12),
            ],
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
