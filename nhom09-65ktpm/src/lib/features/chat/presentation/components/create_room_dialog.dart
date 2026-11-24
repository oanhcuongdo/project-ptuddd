import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/app_button.dart';
import '../../../../core/components/app_error_text.dart';
import '../../../../core/components/app_text_field.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/data/models/language_model.dart';
import '../../data/models/conversation_model.dart';
import '../providers/chat_provider.dart';

/// Hộp thoại tạo Phòng học nhóm mới:
/// - Hiển thị Người quản lý phòng (chủ phòng)
/// - Tên phòng & Ngôn ngữ (tải động từ bảng `languages`)
/// - Yêu cầu trình độ: Radio "Không yêu cầu" / "Có yêu cầu (A1–B2)"
/// - Giới hạn thành viên: Radio "Không giới hạn" / "Giới hạn số lượng"
/// - Mô tả / nội quy phòng (không bắt buộc)
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

  String? _selectedLang;
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
    super.dispose();
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
        );

    if (mounted && created != null) {
      Navigator.of(context).pop<ConversationModel>(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final displayManager = widget.managerName.trim().isNotEmpty
        ? widget.managerName.trim()
        : 'Bạn';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tạo phòng học nhóm mới',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: chat.isCreating
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Người quản lý phòng: $displayManager',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _nameController,
                  label: 'Tên phòng học nhóm',
                  hintText: 'Ví dụ: CLB Luyện Tiếng Anh Giao Tiếp',
                  prefixIcon: Icons.groups_outlined,
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Tên phòng tối thiểu 3 ký tự'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLang,
                  decoration: InputDecoration(
                    labelText: 'Ngôn ngữ luyện tập',
                    prefixIcon: const Icon(Icons.translate_rounded),
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: widget.languages
                      .map(
                        (lang) => DropdownMenuItem<String>(
                          value: lang.code,
                          child: Text('${lang.flagCode} ${lang.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedLang = v;
                    _localError = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Yêu cầu trình độ',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _RadioChoiceTile(
                        label: 'Không yêu cầu',
                        selected: !_requireLevel,
                        onTap: () => setState(() {
                          _requireLevel = false;
                          _selectedLevel = null;
                          _localError = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _RadioChoiceTile(
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
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLevel,
                    decoration: InputDecoration(
                      labelText: 'Chọn trình độ yêu cầu',
                      filled: true,
                      fillColor: AppColors.surfaceWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Giới hạn thành viên',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _RadioChoiceTile(
                        label: 'Không giới hạn',
                        selected: !_limitMembers,
                        onTap: () => setState(() {
                          _limitMembers = false;
                          _localError = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _RadioChoiceTile(
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
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _maxMembersController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Số thành viên tối đa (2 – 200)',
                      hintText: 'Ví dụ: 20',
                      prefixIcon: const Icon(Icons.people_outline_rounded),
                      filled: true,
                      fillColor: AppColors.surfaceWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (v) {
                      if (!_limitMembers) return null;
                      final parsed = int.tryParse((v ?? '').trim());
                      if (parsed == null || parsed < 2 || parsed > 200) {
                        return 'Nhập số từ 2 đến 200';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Chế độ tham gia phòng',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _RadioChoiceTile(
                        label: 'Vào ngay',
                        selected: !_requireApproval,
                        onTap: () => setState(() => _requireApproval = false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _RadioChoiceTile(
                        label: 'Cần kiểm duyệt',
                        selected: _requireApproval,
                        onTap: () => setState(() => _requireApproval = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Mô tả / Nội quy phòng (không bắt buộc)',
                    hintText: 'Ví dụ: Mỗi tối 20h cùng vào luyện nói 20 phút...',
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                AppErrorText(message: _localError ?? chat.errorMessage),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Tạo phòng nhóm ngay',
                  icon: Icons.add_circle_outline_rounded,
                  isLoading: chat.isCreating,
                  onPressed: widget.languages.isEmpty ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioChoiceTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RadioChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
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
