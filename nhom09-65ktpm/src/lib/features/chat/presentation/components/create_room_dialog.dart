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

/// Hộp thoại tạo Phòng học nhóm mới — ngôn ngữ tải động từ bảng `languages` (Supabase).
class CreateRoomDialog extends StatefulWidget {
  final String createdBy;
  final List<LanguageModel> languages;

  const CreateRoomDialog({
    super.key,
    required this.createdBy,
    required this.languages,
  });

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _topicController = TextEditingController();
  final _descController = TextEditingController();
  final _maxMembersController = TextEditingController();

  String? _selectedLang;
  String? _selectedLevel;
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
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
    if (_selectedLevel == null) {
      setState(() => _localError = 'Vui lòng chọn trình độ phù hợp.');
      return;
    }

    final maxMembers = int.tryParse(_maxMembersController.text.trim());
    if (maxMembers == null || maxMembers < 2 || maxMembers > 50) {
      setState(
        () => _localError = 'Số thành viên tối đa phải từ 2 đến 50 người.',
      );
      return;
    }

    setState(() => _localError = null);

    final created = await context.read<ChatProvider>().createGroupRoom(
          createdBy: widget.createdBy,
          name: _nameController.text,
          description: _descController.text,
          topicCategory: _topicController.text,
          level: _selectedLevel!,
          targetLang: _selectedLang!,
          maxMembers: maxMembers,
        );

    if (mounted && created != null) {
      Navigator.of(context).pop<ConversationModel>(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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
                const SizedBox(height: 4),
                const Text(
                  'Phòng sẽ hiển thị công khai tại mục Khám phá để mọi người cùng tham gia luyện giao tiếp.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _nameController,
                  label: 'Tên phòng học nhóm',
                  hintText: 'Ví dụ: Luyện Tiếng Anh A2 - Du lịch',
                  prefixIcon: Icons.groups_outlined,
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Tên phòng tối thiểu 3 ký tự'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _topicController,
                  label: 'Chủ đề hội thoại',
                  hintText: 'Ví dụ: Du lịch, Đời sống, Phỏng vấn...',
                  prefixIcon: Icons.topic_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập chủ đề phòng'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedLang,
                        decoration: InputDecoration(
                          labelText: 'Ngôn ngữ',
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
                                child: Text('${lang.flagCode} ${lang.shortLabel}'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedLang = v;
                          _localError = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedLevel,
                        decoration: InputDecoration(
                          labelText: 'Trình độ',
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
                                child: Text(lvl),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedLevel = v;
                          _localError = null;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _maxMembersController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Số thành viên tối đa (2 – 50)',
                    hintText: 'Ví dụ: 20',
                    prefixIcon: const Icon(Icons.people_outline_rounded),
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) {
                    final parsed = int.tryParse((v ?? '').trim());
                    if (parsed == null || parsed < 2 || parsed > 50) {
                      return 'Nhập số từ 2 đến 50';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Mô tả ngắn (không bắt buộc)',
                    hintText: 'Giới thiệu mục tiêu hoặc nội quy của phòng...',
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
