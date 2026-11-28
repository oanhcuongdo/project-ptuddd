import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../providers/auth_providers.dart';
import '../repository/auth_repository.dart';

/// Màn hình Chỉnh sửa hồ sơ cá nhân.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    final user =
        ref.read(authStateProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 720,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (mounted) setState(() => _avatarBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không chọn được ảnh: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập họ và tên.')),
      );
      return;
    }

    final updated = await ref.read(authControllerProvider.notifier).updateProfile(
          displayName: name,
          phoneNumber: _phoneCtrl.text.trim(),
          avatarBytes: _avatarBytes,
        );
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.hasError || updated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error?.toString() ?? 'Không cập nhật được hồ sơ.'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật thông tin cá nhân.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final user =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa thông tin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: _avatarBytes != null
                      ? MemoryImage(_avatarBytes!)
                      : (user?.avatarUrl != null
                          ? NetworkImage(user!.avatarUrl!) as ImageProvider
                          : null),
                  child: _avatarBytes == null && user?.avatarUrl == null
                      ? Text(
                          user?.initials ?? 'TB',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                      onPressed: isLoading ? null : _pickAvatar,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppInsetCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  enabled: !isLoading,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại (tùy chọn)',
                    hintText: '09xx xxx xxx',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: isLoading ? 'Đang lưu...' : 'Lưu thay đổi',
            onPressed: isLoading ? null : _save,
          ),
        ],
      ),
    );
  }
}
