import 'package:flutter/material.dart';

import '../../../core/location_service.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: SwitchListTile(
        secondary: Icon(
          _value ? Icons.volunteer_activism : Icons.bedtime,
          color: _value ? scheme.primary : scheme.outline,
        ),
        title: Text(_value ? 'Sẵn sàng hỗ trợ' : 'Tạm nghỉ'),
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
