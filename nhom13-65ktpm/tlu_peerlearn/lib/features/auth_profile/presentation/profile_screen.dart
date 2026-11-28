import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/responsive_container.dart';
import '../data/auth_repository.dart';
import '../domain/user_profile.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final UserProfile? initialProfile;

  const ProfileScreen({super.key, this.initialProfile});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _facultyController;
  late final TextEditingController _classNameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile ?? ref.read(currentProfileProvider).value;
    _fullNameController = TextEditingController(text: p?.fullName ?? '');
    _studentIdController = TextEditingController(text: p?.studentId ?? '');
    _facultyController = TextEditingController(text: p?.faculty ?? '');
    _classNameController = TextEditingController(text: p?.className ?? '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _facultyController.dispose();
    _classNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile =
        widget.initialProfile ?? ref.read(currentProfileProvider).value;
    if (profile == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            userId: profile.id,
            fullName: _fullNameController.text,
            studentId: _studentIdController.text,
            faculty: _facultyController.text,
            className: _classNameController.text,
            phone: _phoneController.text,
          );
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật hồ sơ thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật hồ sơ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        widget.initialProfile ?? ref.watch(currentProfileProvider).value;
    final initialLetter = (profile?.fullName.isNotEmpty == true)
        ? profile!.fullName[0].toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: SingleChildScrollView(
        child: ResponsiveContainer(
          maxWidth: 560,
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  child: Text(
                    initialLetter,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (profile != null)
                Text(
                  profile.email,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập họ và tên'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mã sinh viên *',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Vui lòng nhập mã sinh viên';
                  if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                    return 'Mã sinh viên phải gồm đúng 10 chữ số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _facultyController,
                decoration: const InputDecoration(
                  labelText: 'Khoa / Viện',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _classNameController,
                decoration: const InputDecoration(
                  labelText: 'Lớp sinh hoạt',
                  prefixIcon: Icon(Icons.class_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

