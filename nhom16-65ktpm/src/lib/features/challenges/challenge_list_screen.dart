import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/challenge_model.dart';
import '../../data/repositories/challenge_repository.dart';
import '../../data/repositories/fund_repository.dart';
import 'challenge_detail_screen.dart';

/// Màn hình Danh sách & Quản lý Thử thách việc tốt (ChallengeListScreen)
/// Phụ trách: Nguyễn Văn Huỳnh (Nhóm trưởng)
/// - Đọc dữ liệu động từ SQLite qua IChallengeRepository
/// - Tìm kiếm và lọc theo danh mục
/// - Phân quyền Admin: Tạo mới và Chỉnh sửa thử thách trực tiếp vào SQLite
class ChallengeListScreen extends StatefulWidget {
  final VoidCallback? onJoinChallenge;
  final VoidCallback? onChallengesUpdated;
  final IChallengeRepository? challengeRepository;

  const ChallengeListScreen({
    super.key,
    this.onJoinChallenge,
    this.onChallengesUpdated,
    this.challengeRepository,
  });

  @override
  State<ChallengeListScreen> createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends State<ChallengeListScreen> {
  late final IChallengeRepository _challengeRepo;
  final TextEditingController _searchController = TextEditingController();

  List<ChallengeModel> _challenges = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tất cả';
  String _searchQuery = '';

  static const List<String> _categories = [
    'Tất cả',
    'Kỷ luật',
    'Gia sư',
    'Học tập',
    'Sức khỏe',
    'Cộng đồng',
  ];

  static const List<Map<String, dynamic>> _iconOptions = [
    {'key': 'wb_sunny', 'label': 'Dậy sớm', 'icon': Icons.alarm_rounded},
    {'key': 'school', 'label': 'Gia sư', 'icon': Icons.school_rounded},
    {'key': 'psychology', 'label': 'Học tập', 'icon': Icons.psychology_rounded},
    {
      'key': 'directions_run',
      'label': 'Thể thao',
      'icon': Icons.directions_run_rounded,
    },
    {
      'key': 'volunteer_activism',
      'label': 'Cộng đồng',
      'icon': Icons.volunteer_activism_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _challengeRepo =
        widget.challengeRepository ?? FundRepository.instance.challengeRepo;
    _loadChallenges();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    try {
      final list = await _challengeRepo.getChallenges();
      if (!mounted) return;
      setState(() {
        _challenges = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _challenges = [];
        _isLoading = false;
      });
    }
  }

  List<ChallengeModel> get _filteredChallenges {
    final queryTrimmed = _searchQuery.trim().toLowerCase();
    final keywords = queryTrimmed.isEmpty
        ? const <String>[]
        : queryTrimmed
            .split(RegExp(r'\s+'))
            .where((k) => k.isNotEmpty)
            .toList();

    return _challenges.where((c) {
      final matchCategory =
          _selectedCategory == 'Tất cả' || c.category == _selectedCategory;
      if (!matchCategory) return false;
      if (keywords.isEmpty) return true;

      final titleLower = c.title.toLowerCase();
      final descLower = c.description.toLowerCase();
      final catLower = c.category.toLowerCase();
      final targetLower = c.target.toLowerCase();

      // Tất cả từ khóa tách biệt đều được khớp linh hoạt
      return keywords.every((kw) =>
          titleLower.contains(kw) ||
          descLower.contains(kw) ||
          catLower.contains(kw) ||
          targetLower.contains(kw));
    }).toList();
  }

  void _openChallengeDetail(ChallengeModel challenge) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChallengeDetailScreen(
          challenge: challenge,
          onJoinNow: widget.onJoinChallenge,
        ),
      ),
    );
  }

  /// Mở BottomSheet Tạo mới hoặc Chỉnh sửa thử thách (Chỉ dành cho Admin)
  Future<void> _showChallengeFormSheet({ChallengeModel? existing}) async {
    final isEditing = existing != null;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChallengeFormSheet(
        existing: existing,
        categories: _categories.where((c) => c != 'Tất cả').toList(),
        iconOptions: _iconOptions,
        onSave: (challenge) => _challengeRepo.addChallenge(challenge),
      ),
    );

    if (saved == true) {
      await _loadChallenges();
      widget.onChallengesUpdated?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Đã cập nhật thử thách thành công!'
                : 'Đã thêm thử thách mới vào CSDL!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = AuthService.instance.isAdmin;
    final items = _filteredChallenges;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadChallenges,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // 1. HEADER + NÚT TẠO MỚI (ADMIN) / THAM GIA (MEMBER)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danh Mục Thử Thách',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_challenges.length} thử thách đang mở từ SQLite',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                FilledButton.icon(
                  onPressed: () => _showChallengeFormSheet(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Tạo mới'),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: widget.onJoinChallenge,
                  icon: const Icon(Icons.photo_camera_rounded, size: 16),
                  label: const Text('Nộp ảnh'),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. THANH TÌM KIẾM
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Tìm thử thách việc tốt...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.trim().isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. BỘ LỌC DANH MỤC
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 4. DANH SÁCH THỬ THÁCH TỪ SQLITE
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_flags_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Không tìm thấy thử thách phù hợp',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thử đổi từ khóa tìm kiếm hoặc chọn danh mục "Tất cả".',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...items.map((c) => _buildChallengeCard(c, isAdmin, theme)),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(
    ChallengeModel c,
    bool isAdmin,
    ThemeData theme,
  ) {
    final color = ChallengeDetailScreen.getCategoryColor(c.category);
    final icon = ChallengeDetailScreen.getIconData(c.icon);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openChallengeDetail(c),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${c.formattedRewardAmount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                IconButton(
                  tooltip: 'Chỉnh sửa thử thách',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.primary,
                  onPressed: () => _showChallengeFormSheet(existing: c),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// BottomSheet StatefulWidget quản lý lifecycle của TextEditingController an toàn
class _ChallengeFormSheet extends StatefulWidget {
  final ChallengeModel? existing;
  final List<String> categories;
  final List<Map<String, dynamic>> iconOptions;
  final Future<int> Function(ChallengeModel challenge) onSave;

  const _ChallengeFormSheet({
    required this.existing,
    required this.categories,
    required this.iconOptions,
    required this.onSave,
  });

  @override
  State<_ChallengeFormSheet> createState() => _ChallengeFormSheetState();
}

class _ChallengeFormSheetState extends State<_ChallengeFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _rewardCtrl;
  late String _selectedCategory;
  late String _selectedIcon;
  String? _errorText;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _rewardCtrl = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.rewardAmount.toInt().toString()
          : '20000',
    );
    _selectedCategory = widget.existing?.category ?? 'Kỷ luật';
    _selectedIcon = widget.existing?.icon ?? 'wb_sunny';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _rewardCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final rewardDigits = _rewardCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final reward = double.tryParse(rewardDigits);

    if (title.isEmpty || desc.isEmpty) {
      setState(() => _errorText = 'Vui lòng nhập đầy đủ Tên thử thách và Mô tả.');
      return;
    }
    if (reward == null || reward <= 0) {
      setState(() => _errorText = 'Mức tài trợ phải là số lớn hơn 0 đ.');
      return;
    }

    final challenge = ChallengeModel(
      id: widget.existing?.id ?? 'ch_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: desc,
      rewardAmount: reward,
      category: _selectedCategory,
      icon: _selectedIcon,
      isActive: widget.existing?.isActive ?? true,
    );

    await widget.onSave(challenge);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Chỉnh Sửa Thử Thách' : 'Tạo Thử Thách Mới',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorText!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Tên thử thách *',
                hintText: 'vd: Đọc 20 trang sách mỗi ngày',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Mô tả & Thể lệ *',
                hintText: 'Mô tả điều kiện hoàn thành và ảnh chụp...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rewardCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Mức tài trợ vào Quỹ (VNĐ) *',
                hintText: 'vd: 25000',
                suffixText: 'đ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Danh mục:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: widget.categories
                  .map((cat) => ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            const Text(
              'Biểu tượng:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: widget.iconOptions.map((opt) {
                final key = opt['key'] as String;
                return ChoiceChip(
                  avatar: Icon(opt['icon'] as IconData, size: 16),
                  label: Text(opt['label'] as String),
                  selected: _selectedIcon == key,
                  onSelected: (_) => setState(() => _selectedIcon = key),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
              label: Text(
                _isEditing ? 'Lưu Thay Đổi' : 'Tạo Thử Thách',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
