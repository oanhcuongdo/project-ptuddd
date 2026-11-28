import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/hci_components.dart';
import '../../../models/shop.dart';
import '../../../repositories/auth_repository.dart';
import '../data/owner_shop_repository.dart';
import '../data/shop_image_uploader.dart';
import '../data/shop_location_rules.dart';
import 'shop_location_picker.dart';

class ShopEditorScreen extends StatefulWidget {
  const ShopEditorScreen({
    super.key,
    this.shop,
    this.onSaved,
    this.showLogout = false,
  });

  final Shop? shop;

  /// Callback dùng khi mở trực tiếp từ AuthGate onboarding (không có route trước).
  final VoidCallback? onSaved;
  final bool showLogout;

  @override
  State<ShopEditorScreen> createState() => _ShopEditorScreenState();
}

class _ShopEditorScreenState extends State<ShopEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = OwnerShopRepository();
  final _imageUploader = ShopImageUploader();
  final _picker = ImagePicker();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _imageUrl;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late String _category;
  late TimeOfDay _openTime;
  late TimeOfDay _closeTime;
  bool _saving = false;
  XFile? _image;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    final s = widget.shop;
    _name = TextEditingController(text: s?.name ?? '');
    _phone = TextEditingController(text: s?.phone ?? '');
    _address = TextEditingController(text: s?.address ?? '');
    _imageUrl = TextEditingController(text: s?.imageUrl ?? '');
    _latitude = TextEditingController(
      text: s == null ? '' : s.latitude.toStringAsFixed(6),
    );
    _longitude = TextEditingController(
      text: s == null ? '' : s.longitude.toStringAsFixed(6),
    );
    _category = s?.category ?? 'repair_shop';
    _openTime = _parseTime(s?.openTime, const TimeOfDay(hour: 7, minute: 0));
    _closeTime = _parseTime(s?.closeTime, const TimeOfDay(hour: 21, minute: 0));
  }

  TimeOfDay _parseTime(String? value, TimeOfDay fallback) {
    final parts = value?.split(':') ?? [];
    if (parts.length < 2) return fallback;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return fallback;
    }
    return TimeOfDay(hour: h, minute: m);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _imageUrl.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _sqlTime(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:00';

  Future<void> _selectTime(bool opening) async {
    final value = await showTimePicker(
      context: context,
      initialTime: opening ? _openTime : _closeTime,
    );
    if (value == null || !mounted) return;
    setState(() {
      if (opening) {
        _openTime = value;
      } else {
        _closeTime = value;
      }
    });
  }

  Future<void> _selectImage(ImageSource source) async {
    if (_saving) return;
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final extension = file.name.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png'}.contains(extension)) {
        throw const AppException('Chỉ chấp nhận ảnh JPG hoặc PNG.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.lengthInBytes > ShopImageUploader.maxBytes) {
        throw const AppException('Ảnh phải nhỏ hơn hoặc bằng 5 MB.');
      }
      if (mounted) {
        setState(() {
          _image = file;
          _imageBytes = bytes;
        });
      }
    } on AppException catch (e) {
      _message(e.message);
    } catch (_) {
      _message('Không chọn được ảnh. Hãy thử lại.');
    }
  }

  Future<void> _pickLocation() async {
    if (_saving) return;
    final lat = double.tryParse(_latitude.text.trim());
    final lng = double.tryParse(_longitude.text.trim());
    LatLng? initial;
    if (ShopLocationRules.validateCoordinates(lat, lng) == null) {
      initial = LatLng(lat!, lng!);
    }
    final selected = await Navigator.of(context).push<ShopPickedLocation>(
      MaterialPageRoute(
        builder: (_) => ShopLocationPicker(
          initialPosition: initial,
          initialAddress: _address.text,
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _latitude.text = selected.position.latitude.toStringAsFixed(6);
      _longitude.text = selected.position.longitude.toStringAsFixed(6);
      _address.text = selected.address;
    });
    _message('Đã cập nhật vị trí tiệm.');
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) {
      _message('Vui lòng kiểm tra lại các thông tin báo đỏ.');
      return;
    }
    final lat = double.tryParse(_latitude.text.trim());
    final lng = double.tryParse(_longitude.text.trim());
    final error = ShopLocationRules.validateCoordinates(lat, lng);
    if (error != null) {
      _message(error);
      return;
    }
    if (_openTime == _closeTime) {
      _message('Giờ mở và giờ đóng phải khác nhau.');
      return;
    }
    setState(() => _saving = true);
    String? uploadedPath;
    try {
      var imageUrl = _imageUrl.text.trim();
      if (_image != null) {
        final uploaded = await _imageUploader.uploadWithPath(_image!);
        imageUrl = uploaded.url;
        uploadedPath = uploaded.path;
      }
      final draft = ShopDraft(
        name: _name.text,
        category: _category,
        phone: _phone.text,
        address: _address.text,
        latitude: lat!,
        longitude: lng!,
        openTime: _sqlTime(_openTime),
        closeTime: _sqlTime(_closeTime),
        imageUrl: imageUrl,
      );
      try {
        if (widget.shop == null) {
          await _repository.create(draft);
        } else {
          await _repository.update(shop: widget.shop!, draft: draft);
        }
      } catch (_) {
        if (uploadedPath != null) await _imageUploader.remove(uploadedPath);
        rethrow;
      }
      if (!mounted) return;
      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        Navigator.of(context).pop(true);
      }
    } on AppException catch (e) {
      _message(e.message);
    } catch (e) {
      debugPrint('Save shop error: $e');
      _message(
        'Không lưu được hồ sơ tiệm. Hãy kiểm tra mạng và quyền Supabase.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.shop != null;
    final approved = widget.shop?.status == 'approved';
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Chỉnh sửa tiệm' : 'Đăng ký tiệm'),
        actions: [
          if (widget.showLogout)
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: () => confirmAndSignOut(context),
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!editing) ...[
              const FeedbackBanner(
                message: 'Hồ sơ mới sẽ chờ Admin phê duyệt trước khi hiển thị trên bản đồ.',
                tone: FeedbackTone.info,
              ),
              const SizedBox(height: 12),
            ],
            if (approved) ...[
              const FeedbackBanner(
                message:
                    'Nếu thay tên, loại hình hoặc vị trí, tiệm sẽ chuyển về trạng thái chờ phê duyệt lại.',
                tone: FeedbackTone.warning,
              ),
              const SizedBox(height: 12),
            ],
            if (widget.shop?.status == 'rejected') ...[
              FeedbackBanner(
                title: 'Hồ sơ bị từ chối',
                message:
                    widget.shop?.rejectionReason ?? 'Chưa có lý do cụ thể.',
                tone: FeedbackTone.error,
              ),
              const SizedBox(height: 12),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      icon: Icons.storefront_rounded,
                      title: 'Thông tin cơ sở',
                      color: AppColors.motoOrange,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _name,
                      maxLength: 150,
                      decoration: const InputDecoration(labelText: 'Tên tiệm *'),
                      validator: (v) {
                        final n = v?.trim().length ?? 0;
                        return n >= 3 && n <= 150
                            ? null
                            : 'Tên tiệm phải từ 3 đến 150 ký tự.';
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Loại cơ sở *',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'repair_shop',
                          child: Text('Tiệm sửa xe'),
                        ),
                        DropdownMenuItem(
                          value: 'gas_station',
                          child: Text('Cây xăng'),
                        ),
                      ],
                      onChanged: _saving
                          ? null
                          : (v) {
                              if (v != null) setState(() => _category = v);
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(labelText: 'Hotline *'),
                      validator: (v) =>
                          RegExp(r'^0[0-9]{9}$').hasMatch(v?.trim() ?? '')
                              ? null
                              : 'Số điện thoại phải gồm 10 chữ số, bắt đầu bằng 0.',
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _address,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ (có thể sửa) *',
                      ),
                      validator: (v) => (v?.trim().isNotEmpty ?? false)
                          ? null
                          : 'Vui lòng nhập địa chỉ tiệm.',
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      icon: Icons.schedule_rounded,
                      title: 'Giờ hoạt động & Vị trí bản đồ',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : () => _selectTime(true),
                            icon: const Icon(Icons.schedule),
                            label: Text('Mở: ${_openTime.format(context)}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : () => _selectTime(false),
                            icon: const Icon(Icons.schedule),
                            label: Text('Đóng: ${_closeTime.format(context)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickLocation,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Chọn vị trí trên bản đồ'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitude,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Vĩ độ *',
                            ),
                            validator: (v) =>
                                ShopLocationRules.validateCoordinates(
                              double.tryParse(v?.trim() ?? ''),
                              double.tryParse(_longitude.text.trim()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _longitude,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Kinh độ *',
                            ),
                            validator: (v) =>
                                ShopLocationRules.validateCoordinates(
                              double.tryParse(_latitude.text.trim()),
                              double.tryParse(v?.trim() ?? ''),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      icon: Icons.photo_camera_outlined,
                      title: 'Hình ảnh mặt tiền',
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saving
                                ? null
                                : () => _selectImage(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera),
                            label: const Text('Chụp ảnh'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saving
                                ? null
                                : () => _selectImage(ImageSource.gallery),
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Chọn ảnh'),
                          ),
                        ),
                      ],
                    ),
                    if (_imageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else if (_imageUrl.text.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imageUrl.text.trim(),
                            height: 130,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Text('Không hiển thị được ảnh hiện tại.'),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _imageUrl,
                      decoration: const InputDecoration(
                        labelText: 'URL ảnh hiện tại (tùy chọn)',
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return null;
                        final u = Uri.tryParse(value);
                        return u != null &&
                                u.hasAuthority &&
                                (u.scheme == 'https' || u.scheme == 'http')
                            ? null
                            : 'Đường dẫn ảnh không hợp lệ.';
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Đang lưu...' : 'Lưu thông tin tiệm'),
            ),
          ],
        ),
      ),
    );
  }
}
