import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/player_profile_model.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'analytics_screen.dart';
import 'login_screen.dart';
import 'reminder_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  final _fullNameController = TextEditingController();
  final _jerseyController = TextEditingController(text: '10');
  final _clubController = TextEditingController(text: 'FC 65KTPM');

  String _selectedPosition = 'Tiền đạo';
  String _selectedFoot = 'Chân phải';
  String? _avatarUrl;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  final List<String> _positions = [
    'Tiền đạo',
    'Tiền vệ',
    'Hậu vệ',
    'Thủ môn',
  ];

  final List<String> _preferredFeet = [
    'Chân phải',
    'Chân trái',
    'Hai chân',
  ];

  // Danh sách các avatar phong cách cầu thủ có sẵn
  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=150', // Soccer ball
    'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=150', // Player action
    'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=150', // Football stadium
    'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?w=150', // Player boot
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _jerseyController.dispose();
    _clubController.dispose();
    super.dispose();
  }

  // Tải dữ liệu hồ sơ cầu thủ thông qua ProfileService
  Future<void> _loadUserProfile() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    try {
      final profile = await _profileService.getProfile(user.id);

      if (profile != null) {
        _fullNameController.text = profile.fullName;
        _selectedPosition = profile.position;
        _selectedFoot = profile.preferredFoot;
        _jerseyController.text = profile.jerseyNumber.toString();
        _clubController.text = profile.clubTeam;
        _avatarUrl = profile.avatarUrl;
      } else {
        // Nếu chưa có dòng profile thì nạp từ metadata đăng ký
        final meta = user.userMetadata;
        if (meta != null) {
          _fullNameController.text = meta['full_name'] ?? '';
          _selectedPosition = meta['position'] ?? 'Tiền đạo';
          _selectedFoot = meta['preferred_foot'] ?? 'Chân phải';
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải hồ sơ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Lưu thông tin hồ sơ cầu thủ qua ProfileService
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final profile = PlayerProfileModel(
        id: user.id,
        fullName: _fullNameController.text.trim(),
        position: _selectedPosition,
        preferredFoot: _selectedFoot,
        jerseyNumber: int.tryParse(_jerseyController.text.trim()) ?? 10,
        clubTeam: _clubController.text.trim(),
        avatarUrl: _avatarUrl,
        updatedAt: DateTime.now(),
      );

      await _profileService.saveProfile(profile);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Đã cập nhật hồ sơ cầu thủ thành công!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Phân giải ảnh Avatar hỗ trợ cả Base64 (lưu trực tiếp trong CSDL) và URL (Storage/Web)
  ImageProvider? _getAvatarImageProvider(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIndex = trimmed.indexOf(',');
        final base64Content = commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
        return MemoryImage(base64Decode(base64Content));
      } catch (e) {
        debugPrint('Lỗi giải mã Base64 avatar: $e');
        return null;
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    } else {
      // Thử giải mã nếu là chuỗi Base64 thuần
      try {
        return MemoryImage(base64Decode(trimmed));
      } catch (_) {
        return null;
      }
    }
  }

  // Tải ảnh từ thư viện hoặc chụp camera và lưu vào CSDL
  Future<void> _pickAndUploadImage({ImageSource source = ImageSource.gallery}) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 75,
      );

      if (image == null) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      final Uint8List imageBytes = await image.readAsBytes();
      final String fileExt = (image.name.contains('.') ? image.name.split('.').last : 'jpg').toLowerCase();

      // 1. Mã hóa Base64 để lưu trực tiếp vào CSDL bảng player_profiles
      final String base64String = base64Encode(imageBytes);
      final String base64DataUri = 'data:image/$fileExt;base64,$base64String';

      String finalAvatarUrl = base64DataUri;
      bool isStorage = false;

      // 2. Thử upload lên Supabase Storage nếu bucket 'avatars' đã tồn tại
      try {
        final storageUrl = await _profileService.uploadAvatar(
          userId: user.id,
          imageBytes: imageBytes,
          fileExtension: fileExt,
        );
        finalAvatarUrl = storageUrl;
        isStorage = true;
      } catch (storageErr) {
        debugPrint('Supabase Storage chưa tạo bucket hoặc bị lỗi ($storageErr). Tự động lưu Base64 vào CSDL.');
      }

      setState(() {
        _avatarUrl = finalAvatarUrl;
      });

      // 3. Lưu cập nhật ngay vào bảng player_profiles trong CSDL Supabase
      await _profileService.saveProfile(
        PlayerProfileModel(
          id: user.id,
          fullName: _fullNameController.text.trim(),
          position: _selectedPosition,
          preferredFoot: _selectedFoot,
          jerseyNumber: int.tryParse(_jerseyController.text.trim()) ?? 10,
          clubTeam: _clubController.text.trim(),
          avatarUrl: finalAvatarUrl,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isStorage
              ? 'Đã tải ảnh lên Storage và lưu CSDL thành công!'
              : 'Đã lưu ảnh đại diện trực tiếp vào CSDL thành công!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  // Hộp thoại lựa chọn ảnh hoặc nhập URL ảnh
  void _showAvatarOptionsDialog() {
    final urlController = TextEditingController(
      text: (_avatarUrl != null && _avatarUrl!.startsWith('http')) ? _avatarUrl! : '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162235),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cập Nhật Ảnh Đại Diện',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Nút 1: Chọn ảnh từ thiết bị (Thư viện)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(source: ImageSource.gallery);
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('Chọn ảnh từ thiết bị (Lưu vào CSDL)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              // Nút 2: Chụp ảnh từ Camera
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(source: ImageSource.camera);
                },
                icon: const Icon(Icons.camera_alt, color: Color(0xFF10B981)),
                label: const Text('Chụp ảnh từ Camera (Lưu vào CSDL)', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF10B981)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hoặc chọn nhanh Avatar phong cách:',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _presetAvatars.map((url) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _avatarUrl = url);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _avatarUrl == url ? const Color(0xFF10B981) : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(url),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Nhập Link URL
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Hoặc dán URL hình ảnh trực tiếp...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF10B981)),
                    onPressed: () {
                      if (urlController.text.trim().isNotEmpty) {
                        setState(() => _avatarUrl = urlController.text.trim());
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // Hộp thoại đổi mật khẩu mới cho cầu thủ
  void _showChangePasswordDialog() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool isChanging = false;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF162235),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Đổi Mật Khẩu', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                    if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isChanging
                  ? null
                  : () async {
                      if (!dialogFormKey.currentState!.validate()) return;
                      setDialogState(() => isChanging = true);
                      try {
                        await _authService.updatePassword(
                          newPassword: newPasswordController.text.trim(),
                        );
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã cập nhật mật khẩu mới thành công!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isChanging = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
              child: isChanging
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Cập Nhật'),
            ),
          ],
        ),
      ),
    );
  }

  // Xử lý Đăng xuất
  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rời Sân Cỏ?', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi Baller Discipline không?',
          style: TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng Xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF10B981);
    const backgroundColor = Color(0xFF0B1320);
    const cardColor = Color(0xFF162235);
    final user = _authService.currentUser;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: const Text(
          'Hồ Sơ Cầu Thủ',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Thống kê phong độ (Phân hệ 5)',
            icon: const Icon(Icons.insights, color: primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnalyticsScreen(userId: user?.id ?? '')),
              );
            },
          ),
          IconButton(
            tooltip: 'Nhắc lịch ra sân (Phân hệ 5)',
            icon: const Icon(Icons.alarm_on, color: Color(0xFF38BDF8)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReminderScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thẻ Card Tổng Quan Cầu Thủ (Baller Identity Card)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF162235), Color(0xFF111E2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar với nút Camera
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: primaryColor.withValues(alpha: 0.2),
                          backgroundImage: _getAvatarImageProvider(_avatarUrl),
                          child: _avatarUrl == null || _avatarUrl!.isEmpty
                              ? const Icon(Icons.sports_soccer, size: 50, color: Colors.white)
                              : null,
                        ),
                        if (_isUploadingAvatar)
                          const Positioned.fill(
                            child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
                          ),
                        GestureDetector(
                          onTap: _showAvatarOptionsDialog,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Tên Cầu Thủ
                    Text(
                      _fullNameController.text.isNotEmpty ? _fullNameController.text : 'Cầu Thủ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 16),

                    // Badges thông số nhanh
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Vị trí
                        _buildQuickStatBadge(
                          icon: Icons.sports,
                          label: 'Vị Trí',
                          value: _selectedPosition,
                          color: const Color(0xFF38BDF8),
                        ),
                        // Số áo
                        _buildQuickStatBadge(
                          icon: Icons.shield,
                          label: 'Số Áo',
                          value: '#${_jerseyController.text}',
                          color: const Color(0xFFFBBF24),
                        ),
                        // Chân thuận
                        _buildQuickStatBadge(
                          icon: Icons.directions_run,
                          label: 'Chân Thuận',
                          value: _selectedFoot,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Phân hệ 5: Thống Kê & Nhắc Lịch Ra Sân (Nguyễn Hồng Thái)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnalyticsScreen(userId: user?.id ?? ''),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162235),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.insights, color: primaryColor, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Thống Kê Thể Lực',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReminderScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162235),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.alarm_on, color: Color(0xFF38BDF8), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Nhắc Lịch Ra Sân',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Nút Đổi Mật Khẩu
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _showChangePasswordDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF94A3B8),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.lock_reset, size: 20),
                  label: const Text(
                    'ĐỔI MẬT KHẨU TÀI KHOẢN',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Form Chỉnh Sửa Thông Tin
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông Tin Chuyên Môn Cầu Thủ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Họ và tên
                    const Text('Họ và Tên Cầu Thủ', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _fullNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(Icons.person_outline, primaryColor),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Vị trí thi đấu
                    const Text('Vị Trí Thi Đấu Trên Sân', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPosition,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _inputDecoration(Icons.sports, primaryColor),
                      items: _positions.map((pos) => DropdownMenuItem(value: pos, child: Text(pos))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPosition = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Hàng đôi: Chân thuận & Số áo
                    Row(
                      children: [
                        // Chân thuận
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Chân Thuận', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedFoot,
                                dropdownColor: const Color(0xFF0F172A),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: _inputDecoration(Icons.directions_walk, primaryColor),
                                items: _preferredFeet.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedFoot = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Số áo
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Số Áo', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _jerseyController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(Icons.tag, primaryColor),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Nhập số áo';
                                  final num = int.tryParse(val);
                                  if (num == null || num < 0 || num > 99) return '0 - 99';
                                  return null;
                                },
                                onChanged: (val) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Câu lạc bộ / Đội bóng
                    const Text('Câu Lạc Bộ / Đội Bóng Tham Gia', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _clubController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(Icons.groups_outlined, primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nút Lưu Thông Tin
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    elevation: 4,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.save, size: 22),
                  label: Text(
                    _isSaving ? 'ĐANG LƯU DỮ LIỆU...' : 'LƯU HỒ SƠ CẦU THỦ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.1),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Nút Đổi Mật Khẩu
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _showChangePasswordDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF94A3B8),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.lock_reset, size: 20),
                  label: const Text(
                    'ĐỔI MẬT KHẨU TÀI KHOẢN',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(IconData prefixIcon, Color accentColor) {
    return InputDecoration(
      prefixIcon: Icon(prefixIcon, color: accentColor, size: 20),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentColor, width: 1.5),
      ),
    );
  }
}
