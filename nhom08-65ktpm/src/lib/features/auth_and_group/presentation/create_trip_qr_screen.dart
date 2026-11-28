import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/vnd_text_field.dart';
import '../../../models/trip_model.dart';
import '../../goal_and_checklist/data/smart_templates.dart';
import '../../goal_and_checklist/providers/checklist_providers.dart';
import '../providers/trip_providers.dart';
import '../repository/trip_repository.dart';

/// Màn hình Tạo chuyến đi toàn trang — chỉ hiện Bottom Sheet QR mời thành viên sau khi lưu thành công.
class CreateTripQrScreen extends ConsumerStatefulWidget {
  const CreateTripQrScreen({super.key});

  @override
  ConsumerState<CreateTripQrScreen> createState() => _CreateTripQrScreenState();
}

class _CreateTripQrScreenState extends ConsumerState<CreateTripQrScreen> {
  final _nameCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();

  late final String _inviteCode = TripRepository.generateInviteCode();
  Uint8List? _coverBytes;
  TripType _tripType = TripType.other;
  bool _autoApplyTemplate = true;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().add(const Duration(days: 14));
    _endDate = _startDate.add(const Duration(days: 3));
    _startCtrl.text = AppFormatters.formatDate(_startDate);
    _endCtrl.text = AppFormatters.formatDate(_endDate);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _destCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _coverBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Không chọn được ảnh: $e');
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        _startCtrl.text = AppFormatters.formatDate(picked);
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 2));
          _endCtrl.text = AppFormatters.formatDate(_endDate);
        }
      } else {
        _endDate = picked.isBefore(_startDate) ? _startDate : picked;
        _endCtrl.text = AppFormatters.formatDate(_endDate);
      }
    });
  }

  Future<void> _saveTrip() async {
    final title = _nameCtrl.text.trim();
    final destination = _destCtrl.text.trim();
    final targetBudget = AppFormatters.parseSignedVnd(_budgetCtrl.text);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
    );
    final endDay = DateTime(_endDate.year, _endDate.month, _endDate.day);

    String? error;
    if (title.isEmpty || destination.isEmpty) {
      error = 'Vui lòng nhập Tên và Địa điểm chuyến đi.';
    } else if (startDay.isBefore(today)) {
      error = 'Ngày khởi hành không được ở trong quá khứ.';
    } else if (endDay.isBefore(startDay)) {
      error = 'Ngày về phải lớn hơn hoặc bằng ngày khởi hành.';
    } else if (targetBudget <= 0) {
      error = 'Mục tiêu quỹ phải là số dương lớn hơn 0đ.';
    }

    if (error != null) {
      setState(() => _validationError = error);
      _showSnackBar(error);
      return;
    }
    if (_validationError != null) {
      setState(() => _validationError = null);
    }

    final created = await ref
        .read(tripControllerProvider.notifier)
        .createTrip(
          title: title,
          destination: destination,
          startDate: _startDate,
          endDate: _endDate,
          targetBudget: targetBudget,
          tripType: _tripType,
          coverImageBytes: _coverBytes,
          customInviteCode: _inviteCode,
        );
    if (!mounted) return;

    final state = ref.read(tripControllerProvider);
    if (state.hasError || created == null) {
      _showSnackBar(state.error?.toString() ?? 'Không thể tạo chuyến đi.');
      return;
    }

    var templateCount = 0;
    final matchedTemplate = SmartChecklistTemplates.forTripType(_tripType);
    if (_autoApplyTemplate && matchedTemplate != null) {
      templateCount = await ref
          .read(checklistControllerProvider.notifier)
          .applyTemplate(trip: created, template: matchedTemplate);
      if (!mounted) return;
    }

    await _showInviteQrSheet(created, templateCount);
    if (mounted) {
      context.go('/trip/checklist');
    }
  }

  Future<void> _showInviteQrSheet(TripModel trip, int templateCount) async {
    var copied = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tạo chuyến đi thành công!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  templateCount > 0
                      ? 'Đã thêm sẵn $templateCount đầu việc mẫu. Chia sẻ QR này để mời bạn bè:'
                      : 'Chia sẻ mã QR hoặc mã mời bên dưới cho thành viên nhóm:',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariantSoft),
                  ),
                  child: QrImageView(
                    data: 'travelbuddy://join?code=${trip.inviteCode}',
                    version: QrVersions.auto,
                    size: 160,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  trip.inviteCode,
                  style: AppTheme.monoAmount(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: trip.inviteCode),
                          );
                          setSheetState(() => copied = true);
                        },
                        icon: Icon(
                          copied ? Icons.check : Icons.content_copy,
                          size: 18,
                        ),
                        label: Text(copied ? 'Đã sao chép' : 'Sao chép mã'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: const Text('Vào chuyến đi'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(tripControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: isSaving ? null : () => context.pop(),
          child: const Text(
            'Hủy',
            style: TextStyle(color: AppColors.onPrimaryContainer),
          ),
        ),
        leadingWidth: 68,
        title: const Text('Tạo chuyến đi'),
        actions: [
          TextButton(
            key: const Key('create_trip_save_button'),
            onPressed: isSaving ? null : _saveTrip,
            child: Text(
              isSaving ? 'Đang lưu...' : 'Lưu',
              style: const TextStyle(
                color: AppColors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isSaving ? null : _pickCoverImage,
            child: Container(
              height: 128,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              child: _coverBytes != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_coverBytes!, fit: BoxFit.cover),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Đổi ảnh bìa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.primary,
                          size: 26,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Chọn ảnh bìa',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'PNG, JPG tối đa 5MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          const AppSectionHeader(title: 'Thông tin chuyến đi'),
          AppInsetCard(
            child: Column(
              children: [
                _InputRow(
                  fieldKey: const Key('create_trip_title_field'),
                  label: 'Tên',
                  controller: _nameCtrl,
                  hintText: 'VD: Đà Lạt 4N3Đ',
                ),
                const Divider(indent: 16),
                _InputRow(
                  fieldKey: const Key('create_trip_dest_field'),
                  label: 'Địa điểm',
                  controller: _destCtrl,
                  hintText: 'VD: Đà Lạt, Lâm Đồng',
                ),
                const Divider(indent: 16),
                _InputRow(
                  fieldKey: const Key('create_trip_start_date_field'),
                  label: 'Ngày đi',
                  controller: _startCtrl,
                  isMono: true,
                  readOnly: true,
                  onTap: () => _pickDate(isStart: true),
                ),
                const Divider(indent: 16),
                _InputRow(
                  fieldKey: const Key('create_trip_end_date_field'),
                  label: 'Ngày về',
                  controller: _endCtrl,
                  isMono: true,
                  readOnly: true,
                  onTap: () => _pickDate(isStart: false),
                ),
                const Divider(indent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Text('Mục tiêu quỹ', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          key: const Key('create_trip_budget_field'),
                          controller: _budgetCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [VndThousandInputFormatter()],
                          textAlign: TextAlign.right,
                          style: AppTheme.monoAmount(
                            fontSize: 15,
                            color: AppColors.onPrimaryContainer,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'VD: 8.450.000',
                            suffixText: 'đ',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(indent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Text('Loại hình', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<TripType>(
                          key: const Key('create_trip_type_dropdown'),
                          initialValue: _tripType,
                          isExpanded: true,
                          alignment: AlignmentDirectional.centerEnd,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          items: TripType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() => _tripType = val);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
                if (_tripType != TripType.other) ...[
                  const Divider(indent: 16),
                  SwitchListTile(
                    key: const Key('create_trip_auto_template_switch'),
                    value: _autoApplyTemplate,
                    onChanged: isSaving
                        ? null
                        : (v) => setState(() => _autoApplyTemplate = v),
                    title: const Text(
                      'Tự động tạo Checklist mẫu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Áp dụng sẵn bộ "${SmartChecklistTemplates.forTripType(_tripType)?.name ?? _tripType.label}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ],
              ],
            ),
          ),
          if (_validationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                _validationError!,
                key: const Key('create_trip_error_text'),
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: isSaving ? 'Đang tạo chuyến đi...' : 'Tạo chuyến đi & Lấy mã QR',
            icon: Icons.qr_code_2_rounded,
            onPressed: isSaving ? null : _saveTrip,
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.label,
    required this.controller,
    this.fieldKey,
    this.hintText,
    this.isMono = false,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final Key? fieldKey;
  final String? hintText;
  final bool isMono;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: fieldKey,
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              textAlign: TextAlign.right,
              style: isMono
                  ? AppTheme.monoAmount(
                      fontSize: 15,
                      color: AppColors.onSurfaceVariant,
                    )
                  : const TextStyle(
                      fontSize: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
