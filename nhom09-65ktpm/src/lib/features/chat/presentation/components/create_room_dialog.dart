import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/app_error_text.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth_profile/data/models/language_model.dart';
import '../../data/models/conversation_model.dart';
import '../providers/chat_provider.dart';
import '../styles/chat_styles.dart';

/// Hộp thoại tạo Phòng học nhóm mới — thiết kế gọn gàng, sang trọng tông Xanh Ngọc:
/// - Thanh tiêu đề Xanh Ngọc + pill Người quản lý phòng
/// - Thông tin cơ bản: Tên phòng, Ngôn ngữ luyện tập, Định hướng / Kỹ năng (tùy chọn)
/// - Ảnh bìa phòng học (tùy chọn): Xem trước trực tiếp + 5 nền Gradient có sẵn hoặc link ảnh
/// - Quy định phòng: Radio Trình độ, Radio Giới hạn thành viên, Radio Vào ngay / Cần kiểm duyệt
class CreateRoomDialog extends StatefulWidget {
  final String createdBy;
  final String managerName;
  final List<LanguageModel> languages;

  const CreateRoomDialog({
    super.key,
    required this.createdBy,
    required this.managerName,
    required this.languages,
  });

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _maxMembersController = TextEditingController();
  final _coverUrlController = TextEditingController();

  String? _selectedLang;
  String? _selectedFocus;
  String _selectedCoverPreset = ChatStyles.coverPresets.first.key;
  bool _requireLevel = false;
  String? _selectedLevel;
  bool _limitMembers = false;
  bool _requireApproval = false;
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _maxMembersController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  String? get _resolvedCoverValue {
    final customUrl = _coverUrlController.text.trim();
    if (customUrl.isNotEmpty) return customUrl;
    return _selectedCoverPreset;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLang == null) {
      setState(() => _localError = 'Vui lòng chọn ngôn ngữ luyện tập.');
      return;
    }
    if (_requireLevel && _selectedLevel == null) {
      setState(() => _localError = 'Vui lòng chọn trình độ yêu cầu (A1–B2).');
      return;
    }

    int? maxMembers;
    if (_limitMembers) {
      maxMembers = int.tryParse(_maxMembersController.text.trim());
      if (maxMembers == null || maxMembers < 2 || maxMembers > 200) {
        setState(
          () => _localError = 'Số thành viên giới hạn phải từ 2 đến 200 người.',
        );
        return;
      }
    }

    final customCover = _coverUrlController.text.trim();
    if (customCover.isNotEmpty && !customCover.startsWith('http')) {
      setState(
        () => _localError = 'Link ảnh bìa phải bắt đầu bằng http:// hoặc https://.',
      );
      return;
    }

    setState(() => _localError = null);

    final created = await context.read<ChatProvider>().createGroupRoom(
          createdBy: widget.createdBy,
          managerName: widget.managerName,
          name: _nameController.text,
          description: _descController.text,
          level: _requireLevel ? _selectedLevel : null,
          targetLang: _selectedLang!,
          maxMembers: maxMembers,
          requireApproval: _requireApproval,
          coverUrl: _resolvedCoverValue,
          roomFocus: _selectedFocus,
        );

    if (mounted && created != null) {
      Navigator.of(context).pop<ConversationModel>(created);
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 19, color: ChatStyles.tealPrimary)
          : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFB),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCE7EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCE7EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ChatStyles.tealPrimary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final displayManager = widget.managerName.trim().isNotEmpty
        ? widget.managerName.trim()
        : 'Bạn';

    return Dialog(
      backgroundColor: AppColors.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 740),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Xanh Ngọc sang trọng
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ChatStyles.tealDark, ChatStyles.tealPrimary],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tạo phòng học nhóm mới',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Người quản lý phòng: $displayManager',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.90),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: chat.isCreating
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
                ],
              ),
            ),

            // Nội dung Form cuộn mượt
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Tên phòng & Ngôn ngữ (2 cột trên màn rộng)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final nameField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Tên phòng học nhóm *'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameController,
                                onChanged: (_) => setState(() {}),
                                decoration: _inputDecoration(
                                  hintText: 'VD: CLB Tiếng Anh Giao Tiếp',
                                  prefixIcon: Icons.forum_outlined,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().length < 3)
                                        ? 'Tên phòng tối thiểu 3 ký tự'
                                        : null,
                              ),
                            ],
                          );

                          final langField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Ngôn ngữ luyện tập *'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedLang,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  hintText: 'Chọn ngôn ngữ',
                                  prefixIcon: Icons.translate_rounded,
                                ),
                                items: widget.languages
                                    .map(
                                      (lang) => DropdownMenuItem<String>(
                                        value: lang.code,
                                        child: Text(
                                          '${lang.flagCode} ${lang.name}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() {
                                  _selectedLang = v;
                                  _localError = null;
                                }),
                              ),
                            ],
                          );

                          if (constraints.maxWidth >= 460) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: nameField),
                                const SizedBox(width: 12),
                                Expanded(flex: 5, child: langField),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              nameField,
                              const SizedBox(height: 14),
                              langField,
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // 2. Định hướng / Kỹ năng của phòng (tùy chọn)
                      const _FieldLabel('Định hướng kỹ năng (tùy chọn)'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ChatStyles.roomFocusOptions.map((focus) {
                          final active = _selectedFocus == focus;
                          return InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => setState(() {
                              _selectedFocus = active ? null : focus;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? ChatStyles.tealPrimary
                                    : const Color(0xFFF8FAFB),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: active
                                      ? ChatStyles.tealPrimary
                                      : const Color(0xFFDCE7EA),
                                ),
                              ),
                              child: Text(
                                focus,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // 3. Ảnh bìa phòng học (xem trước trực tiếp + chọn màu nền hoặc dán link)
                      const _FieldLabel('Ảnh bìa phòng học (tùy chọn)'),
                      const SizedBox(height: 8),
                      _buildCoverPicker(),

                      const SizedBox(height: 16),

                      // 4. Khối Quy định phòng học (gom nhóm gọn gàng)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2ECEE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Yêu cầu trình độ'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _TealRadioTile(
                                    label: 'Không yêu cầu',
                                    selected: !_requireLevel,
                                    onTap: () => setState(() {
                                      _requireLevel = false;
                                      _selectedLevel = null;
                                      _localError = null;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _TealRadioTile(
                                    label: 'Có yêu cầu',
                                    selected: _requireLevel,
                                    onTap: () => setState(() {
                                      _requireLevel = true;
                                      _localError = null;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            if (_requireLevel) ...[
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedLevel,
                                decoration: _inputDecoration(
                                  hintText: 'Chọn trình độ yêu cầu (A1–B2)',
                                ),
                                items: AppConstants.proficiencyLevels
                                    .map(
                                      (lvl) => DropdownMenuItem<String>(
                                        value: lvl,
                                        child: Text('Trình độ $lvl'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() {
                                  _selectedLevel = v;
                                  _localError = null;
                                }),
                              ),
                            ],
                            const SizedBox(height: 14),
                            const _FieldLabel('Giới hạn thành viên'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _TealRadioTile(
                                    label: 'Không giới hạn',
                                    selected: !_limitMembers,
                                    onTap: () => setState(() {
                                      _limitMembers = false;
                                      _localError = null;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _TealRadioTile(
                                    label: 'Có giới hạn',
                                    selected: _limitMembers,
                                    onTap: () => setState(() {
                                      _limitMembers = true;
                                      _localError = null;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            if (_limitMembers) ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _maxMembersController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: _inputDecoration(
                                  hintText: 'Số thành viên tối đa (2 – 200)',
                                  prefixIcon: Icons.people_outline_rounded,
                                ),
                                validator: (v) {
                                  if (!_limitMembers) return null;
                                  final parsed = int.tryParse((v ?? '').trim());
                                  if (parsed == null ||
                                      parsed < 2 ||
                                      parsed > 200) {
                                    return 'Nhập số từ 2 đến 200';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 14),
                            const _FieldLabel('Chế độ tham gia phòng'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _TealRadioTile(
                                    label: 'Vào ngay',
                                    selected: !_requireApproval,
                                    onTap: () => setState(
                                      () => _requireApproval = false,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _TealRadioTile(
                                    label: 'Cần kiểm duyệt',
                                    selected: _requireApproval,
                                    onTap: () => setState(
                                      () => _requireApproval = true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 5. Mô tả / Nội quy phòng
                      const _FieldLabel('Mô tả / Nội quy phòng (không bắt buộc)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: _inputDecoration(
                          hintText:
                              'Ví dụ: Mỗi tối 20h cùng vào luyện nói 20 phút, tôn trọng mọi người...',
                        ),
                      ),
                      AppErrorText(message: _localError ?? chat.errorMessage),
                    ],
                  ),
                ),
              ),
            ),

            // Footer hành động cố định dưới đáy
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: chat.isCreating
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: (chat.isCreating || widget.languages.isEmpty)
                        ? null
                        : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: ChatStyles.tealPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: chat.isCreating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('Tạo phòng nhóm ngay'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPicker() {
    final customUrl = _coverUrlController.text.trim();
    final hasCustomImage = customUrl.startsWith('http');
    final gradient = ChatStyles.gradientForCoverKey(_selectedCoverPreset) ??
        ChatStyles.coverPresets.first.colors;
    final previewTitle = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Xem trước ảnh bìa phòng học';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live mini cover preview
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 76,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                ),
                if (hasCustomImage)
                  Image.network(
                    customUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                if (hasCustomImage)
                  Container(color: Colors.black.withValues(alpha: 0.30)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          previewTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_selectedFocus != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _selectedFocus!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Hàng chọn màu gradient có sẵn
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ChatStyles.coverPresets.map((preset) {
            final isSelected =
                !hasCustomImage && _selectedCoverPreset == preset.key;
            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => setState(() {
                _selectedCoverPreset = preset.key;
                _coverUrlController.clear();
                _localError = null;
              }),
              child: Container(
                padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ChatStyles.tealSoftBg
                      : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? ChatStyles.tealPrimary
                        : const Color(0xFFDCE7EA),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: preset.colors),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      preset.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? ChatStyles.tealDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _coverUrlController,
          onChanged: (_) => setState(() => _localError = null),
          decoration: _inputDecoration(
            hintText: 'Hoặc dán link ảnh bìa (https://...)',
            prefixIcon: Icons.image_outlined,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _TealRadioTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TealRadioTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ChatStyles.tealSoftBg : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? ChatStyles.tealPrimary : const Color(0xFFDCE7EA),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 17,
              color: selected ? ChatStyles.tealPrimary : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? ChatStyles.tealDark : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
