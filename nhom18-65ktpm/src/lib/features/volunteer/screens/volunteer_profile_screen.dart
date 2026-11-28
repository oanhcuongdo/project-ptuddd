import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/location_service.dart';
import '../../../core/validators.dart';
import '../../../models/user.dart';
import '../../../models/volunteer_profile.dart';
import '../../../repositories/auth_repository.dart';
import '../data/supabase_volunteer_repository.dart';
import '../volunteer_rules.dart';

/// UC-13: đăng ký / cập nhật hồ sơ tình nguyện viên. Pop true khi lưu thành công.
class VolunteerProfileScreen extends StatefulWidget {
  const VolunteerProfileScreen({super.key});

  @override
  State<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _PickedImage {
  const _PickedImage(this.bytes, this.name);

  final Uint8List bytes;
  final String name;
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _tools = TextEditingController();
  final _repo = SupabaseVolunteerRepository();
  final _location = LocationService();
  final _picker = ImagePicker();

  UserModel? _user;
  VolunteerProfile? _old;
  final _skills = <String>{};
  int _radiusKm = volunteerDefaultRadiusKm;
  _PickedImage? _newIdCard;
  Future<String>? _oldIdCardUrl;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phone.dispose();
    _tools.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final user = await AuthRepository().fetchProfile();
      final old = await _repo.myProfile();
      if (!mounted) return;
      setState(() {
        _user = user;
        _old = old;
        _phone.text = old?.phone ?? user?.phone ?? '';
        _tools.text = old?.tools ?? '';
        _skills
          ..clear()
          ..addAll(old?.skills ?? const []);
        _radiusKm = old?.serviceRadiusKm ?? volunteerDefaultRadiusKm;
        final path = old?.idCardUrl ?? '';
        _oldIdCardUrl = path.isEmpty ? null : _repo.idCardViewUrl(path);
      });
    } on AppException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final error = validateIdCard(
        fileName: file.name,
        sizeBytes: bytes.length,
      );
      setState(() {
        _error = error;
        if (error == null) _newIdCard = _PickedImage(bytes, file.name);
      });
    } catch (_) {
      setState(() => _error = 'Không mở được camera / thư viện ảnh.');
    }
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    final hasIdCard = _newIdCard != null || (_old?.idCardUrl ?? '').isNotEmpty;
    final error =
        validateSkills(_skills.toList()) ??
        validateRadius(_radiusKm) ??
        (hasIdCard ? null : 'Vui lòng tải ảnh giấy tờ xác minh');
    setState(() => _error = error);
    if (!formOk || error != null) return;

    setState(() => _saving = true);
    final old = _old;
    String? uploadedPath;
    try {
      // Lấy GPS trước để không ghi hồ sơ dở dang khi chưa cấp quyền vị trí.
      final position = await _location.current();

      var idCardPath = old?.idCardUrl ?? '';
      final picked = _newIdCard;
      if (picked != null) {
        idCardPath = uploadedPath = await _repo.uploadIdCard(
          bytes: picked.bytes,
          fileName: picked.name,
        );
      }

      final VolunteerProfile saved;
      try {
        saved = await _repo.saveProfile(
          phone: _phone.text,
          skills: _skills.toList(),
          tools: _tools.text,
          idCardUrl: idCardPath,
          serviceRadiusKm: _radiusKm,
        );
      } on AppException {
        // Hồ sơ không lưu được thì bỏ ảnh vừa tải để không rác bucket.
        if (uploadedPath != null) await _repo.removeIdCard(uploadedPath);
        rethrow;
      }
      _old = saved;
      await _repo.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (old != null && picked != null && old.idCardUrl != idCardPath) {
        await _repo.removeIdCard(old.idCardUrl);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_successMessage(old, saved))));
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _successMessage(VolunteerProfile? old, VolunteerProfile saved) {
    if (old == null) {
      return 'Hồ sơ đã được gửi, vui lòng chờ Quản trị viên phê duyệt';
    }
    if (saved.status == 'pending' && old.status != 'pending') {
      return old.status == 'rejected'
          ? 'Đã gửi lại hồ sơ, vui lòng chờ Quản trị viên phê duyệt'
          : 'Thông tin thay đổi cần được Quản trị viên duyệt lại';
    }
    return 'Cập nhật hồ sơ thành công';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ tình nguyện viên')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final old = _old;
    final banned = old?.status == 'banned';
    final skillOptions = {...volunteerSkillOptions, ..._skills};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (old != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified_user),
                  title: const Text('Trạng thái hồ sơ'),
                  subtitle: Text(
                    volunteerStatusLabel(
                      old.status,
                      rejectionReason: old.rejectionReason,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _user?.fullName ?? '',
              enabled: false,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              enabled: !_saving && !banned,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại liên hệ',
              ),
              validator: validatePhone,
            ),
            const SizedBox(height: 20),
            Text('Kỹ năng hỗ trợ', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in skillOptions)
                  FilterChip(
                    label: Text(skill),
                    selected: _skills.contains(skill),
                    onSelected: _saving || banned
                        ? null
                        : (selected) => setState(() {
                            selected
                                ? _skills.add(skill)
                                : _skills.remove(skill);
                          }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _tools,
              enabled: !_saving && !banned,
              maxLines: 2,
              maxLength: volunteerToolsMaxLength,
              decoration: const InputDecoration(
                labelText: 'Dụng cụ mang theo (không bắt buộc)',
                hintText: 'VD: bộ vá lốp, bơm điện, dây kéo',
              ),
              validator: validateTools,
            ),
            const SizedBox(height: 8),
            Text(
              'Bán kính hỗ trợ: $_radiusKm km',
              style: theme.textTheme.titleSmall,
            ),
            Slider(
              value: _radiusKm.toDouble(),
              min: volunteerMinRadiusKm.toDouble(),
              max: volunteerMaxRadiusKm.toDouble(),
              divisions: volunteerMaxRadiusKm - volunteerMinRadiusKm,
              label: '$_radiusKm km',
              onChanged: _saving || banned
                  ? null
                  : (value) => setState(() => _radiusKm = value.round()),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final km in volunteerQuickRadiiKm)
                  ChoiceChip(
                    label: Text('$km km'),
                    selected: _radiusKm == km,
                    onSelected: _saving || banned
                        ? null
                        : (_) => setState(() => _radiusKm = km),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Ảnh CCCD / giấy tờ xác minh',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _IdCardPreview(
              newImage: _newIdCard?.bytes,
              oldImageUrl: _oldIdCardUrl,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving || banned
                        ? null
                        : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Chụp ảnh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving || banned
                        ? null
                        : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn ảnh'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Khu vực hoạt động chính được lấy theo vị trí GPS hiện tại khi bạn gửi hồ sơ. '
              'Ảnh giấy tờ chỉ bạn và Quản trị viên xem được.',
              style: theme.textTheme.bodySmall,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving || banned ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(old == null ? 'Gửi hồ sơ' : 'Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdCardPreview extends StatelessWidget {
  const _IdCardPreview({this.newImage, this.oldImageUrl});

  final Uint8List? newImage;
  final Future<String>? oldImageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('Chưa có ảnh giấy tờ'),
    );

    Widget framed(Widget image) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(height: 160, width: double.infinity, child: image),
    );

    final bytes = newImage;
    if (bytes != null) return framed(Image.memory(bytes, fit: BoxFit.cover));

    final url = oldImageUrl;
    if (url == null) return placeholder;

    return FutureBuilder<String>(
      future: url,
      builder: (context, snapshot) {
        final link = snapshot.data;
        if (link == null) {
          return snapshot.hasError
              ? placeholder
              : const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
        }
        return framed(
          Image.network(
            link,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Center(child: Text('Đã có ảnh giấy tờ')),
          ),
        );
      },
    );
  }
}
