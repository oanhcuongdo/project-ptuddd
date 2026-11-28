import 'package:flutter/material.dart';

import '../../../core/location_service.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/hci_components.dart';
import '../../../models/volunteer_profile.dart';
import '../../../repositories/auth_repository.dart';
import '../../sos/data/supabase_sos_repository.dart';
import '../data/supabase_volunteer_repository.dart';
import '../volunteer_rules.dart';

/// UC-11 (phần TNV): công tắc "Sẵn sàng hỗ trợ" / "Tạm nghỉ".
/// Bật: ghi vị trí GPS hiện tại rồi mới bật để được tính vào bán kính nhận SOS.
class AvailabilityCard extends StatefulWidget {
  const AvailabilityCard({
    super.key,
    required this.profile,
    required this.onChanged,
  });

  final VolunteerProfile profile;

  /// Gọi sau khi cập nhật thành công để màn cha tải lại hồ sơ.
  final VoidCallback onChanged;

  @override
  State<AvailabilityCard> createState() => _AvailabilityCardState();
}

class _AvailabilityCardState extends State<AvailabilityCard> {
  final _repo = SupabaseVolunteerRepository();
  final _sosRepo = SupabaseSosRepository();
  final _location = LocationService();

  late bool _value = widget.profile.isAvailable;
  bool _busy = false;

  @override
  void didUpdateWidget(AvailabilityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_busy) _value = widget.profile.isAvailable;
  }

  Future<void> _toggle(bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _value = value;
    });

    try {
      if (value) {
        final position = await _location.current();
        await _repo.updateLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } else if (await _sosRepo.myAcceptedCase() != null) {
        throw const AppException(
          'Vui lòng hoàn thành ca cứu hộ đang xử lý trước khi tạm nghỉ',
        );
      }
      await _repo.setAvailable(value);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Bạn đang sẵn sàng nhận yêu cầu SOS ở gần'
                : 'Đã chuyển sang tạm nghỉ',
          ),
        ),
      );
      widget.onChanged();
    } on AppException catch (e) {
      if (mounted) setState(() => _value = !value);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final approved = profile.status == 'approved';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      decoration: BoxDecoration(
        color: _value ? AppColors.successBg : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _value
              ? AppColors.success.withValues(alpha: 0.45)
              : AppColors.border,
          width: _value ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (_value ? AppColors.success : AppColors.navyDeep)
                .withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile.adaptive(
        activeThumbColor: AppColors.success,
        secondary: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _value
                ? AppColors.success.withValues(alpha: 0.16)
                : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            _value
                ? Icons.volunteer_activism_rounded
                : Icons.bedtime_rounded,
            color: _value ? AppColors.success : AppColors.inkMuted,
          ),
        ),
        title: Row(
          children: [
            LiveStatusDot(
              color: _value ? AppColors.success : AppColors.inkMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _value ? 'Sẵn sàng hỗ trợ' : 'Tạm nghỉ',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _value
                      ? const Color(0xFF047857)
                      : AppColors.inkPrimary,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          approved
              ? 'Đã hoàn thành ${profile.completedCount} ca · bán kính ${profile.serviceRadiusKm} km'
              : volunteerStatusLabel(profile.status),
        ),
        value: _value,
        onChanged: approved && !_busy ? _toggle : null,
      ),
    );
  }
}
