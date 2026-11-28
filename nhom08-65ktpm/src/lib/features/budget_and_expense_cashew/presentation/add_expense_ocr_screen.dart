import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../models/trip_member.dart';
import '../../auth_and_group/providers/auth_providers.dart';
import '../../auth_and_group/providers/trip_providers.dart';
import '../../auth_and_group/repository/auth_repository.dart';
import '../models/budget_envelope.dart';
import '../models/trip_expense.dart';
import '../providers/budget_providers.dart';
import '../utils/cashew_calculator.dart';
import '../utils/receipt_amount_parser.dart';
import 'widgets/cashew_amount_keypad.dart';

class AddExpenseOcrScreen extends ConsumerStatefulWidget {
  const AddExpenseOcrScreen({super.key});

  @override
  ConsumerState<AddExpenseOcrScreen> createState() =>
      _AddExpenseOcrScreenState();
}

class _AddExpenseOcrScreenState extends ConsumerState<AddExpenseOcrScreen> {
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _picker = ImagePicker();
  final Map<String, TextEditingController> _customSplitControllers = {};
  final Set<String> _selectedMemberIds = {};
  String? _selectionTripId;
  String? _receiptPath;
  String? _ocrRawText;
  int? _ocrDetectedAmount;
  String? _selectedEnvelopeId;
  var _selectionCustomized = false;
  var _isCustomSplit = false;
  var _paymentSourceIndex = 1;
  var _isScanning = false;
  var _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    for (final controller in _customSplitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int get _parsedAmount {
    final value = CashewCalculator.evaluate(_amountCtrl.text);
    if (value == null || value < 0 || !value.isFinite) return 0;
    return value.round();
  }

  Future<void> _scanReceipt() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      _showMessage('Quét OCR hiện chỉ hỗ trợ Android và iOS.');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh hóa đơn'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _isScanning = true);
    TextRecognizer? recognizer;
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image == null) return;

      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      final rawText = recognized.text;
      final amount = ReceiptAmountParser.extractAmount(rawText);
      if (amount == null) {
        _showMessage('Không tìm thấy số tiền trên hóa đơn. Hãy nhập thủ công.');
        return;
      }

      setState(() {
        _receiptPath = image.path;
        _ocrRawText = rawText;
        _ocrDetectedAmount = amount;
        _amountCtrl.text = amount.toString();
        _amountCtrl.selection = TextSelection.collapsed(
          offset: _amountCtrl.text.length,
        );
      });
      _showMessage('Đã nhận diện ${MockTripData.formatVnd(amount)}.');
    } catch (error) {
      _showMessage('Không thể quét hóa đơn: $error');
    } finally {
      await recognizer?.close();
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _onKeypadTap(String keyValue) {
    if (keyValue == 'C') {
      setState(_amountCtrl.clear);
    } else if (keyValue == '⌫') {
      setState(() {
        _amountCtrl.text = CashewCalculator.backspace(_amountCtrl.text);
        _amountCtrl.selection = TextSelection.collapsed(
          offset: _amountCtrl.text.length,
        );
      });
    } else if (keyValue == '=') {
      final result = CashewCalculator.evaluate(_amountCtrl.text);
      if (result == null || result < 0 || !result.isFinite) {
        _showMessage('Biểu thức tính tiền không hợp lệ.');
        return;
      }
      setState(() => _amountCtrl.text = result.round().toString());
    } else if (keyValue == '+' || keyValue == '−') {
      setState(() {
        _amountCtrl.text = CashewCalculator.appendOperator(
          _amountCtrl.text,
          keyValue,
        );
        _amountCtrl.selection = TextSelection.collapsed(
          offset: _amountCtrl.text.length,
        );
      });
    } else {
      setState(() {
        _amountCtrl.text = CashewCalculator.appendDigits(
          _amountCtrl.text,
          keyValue,
        );
        _amountCtrl.selection = TextSelection.collapsed(
          offset: _amountCtrl.text.length,
        );
      });
    }
  }

  void _addQuickAmount(int amount) {
    setState(() {
      _amountCtrl.text = (_parsedAmount + amount).toString();
      _amountCtrl.selection = TextSelection.collapsed(
        offset: _amountCtrl.text.length,
      );
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveExpense({
    required String tripId,
    required String memberId,
    required String memberName,
    required List<_ExpenseMember> members,
    required List<BudgetEnvelope> envelopes,
  }) async {
    if (_isSaving) return;
    final title = _titleCtrl.text.trim();
    final amount = _parsedAmount;
    final envelope = envelopes
        .where((item) => item.id == _selectedEnvelopeId)
        .firstOrNull;
    final selectedMembers = members
        .where((member) => _effectiveMemberIds(members).contains(member.id))
        .toList();

    if (title.isEmpty) {
      _showMessage('Vui lòng nhập nội dung khoản chi.');
      return;
    }
    if (amount <= 0) {
      _showMessage('Số tiền phải lớn hơn 0.');
      return;
    }
    if (envelope == null) {
      _showMessage('Vui lòng chọn một hũ ngân sách.');
      return;
    }
    if (selectedMembers.isEmpty) {
      _showMessage('Chọn ít nhất một thành viên để chia khoản chi.');
      return;
    }

    final splitDetails = _buildSplitDetails(selectedMembers, amount);
    if (splitDetails == null) {
      _showMessage('Tổng phần chia phải bằng đúng số tiền khoản chi.');
      return;
    }

    setState(() => _isSaving = true);
    String? receiptImageUrl;
    String? receiptStoragePath;
    var uploadedReceipt = false;
    try {
      if (_receiptPath != null) {
        receiptStoragePath =
            'trips/$tripId/expenses/${DateTime.now().microsecondsSinceEpoch}/receipt.jpg';
        receiptImageUrl = await ref
            .read(supabaseStorageServiceProvider)
            .uploadFile(path: receiptStoragePath, file: File(_receiptPath!));
        uploadedReceipt = true;
      }

      final expense = TripExpense(
        id: '',
        title: title,
        amount: amount,
        envelopeId: envelope.id,
        category: envelope.category,
        paymentSource: _paymentSourceIndex == 0
            ? 'group_fund'
            : 'personal_advance',
        paidBy: memberId,
        paidByName: memberName,
        splitType: _isCustomSplit ? 'exact' : 'equal',
        splitBetween: splitDetails.keys.toList(),
        splitDetails: splitDetails,
        isOcrScanned: _ocrDetectedAmount != null,
        ocrDetectedAmount: _ocrDetectedAmount,
        ocrRawText: _ocrRawText,
        receiptImageUrl: receiptImageUrl,
        receiptStoragePath: receiptStoragePath,
        spentAt: DateTime.now(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        createdBy: memberId,
        createdAt: DateTime.now(),
      );
      await ref
          .read(budgetControllerProvider)
          .addExpense(tripId: tripId, expense: expense);
      if (mounted) context.pop();
    } catch (error) {
      if (uploadedReceipt && receiptStoragePath != null) {
        try {
          await ref
              .read(supabaseStorageServiceProvider)
              .deleteFile(receiptStoragePath);
        } catch (cleanupError) {
          debugPrint('Receipt cleanup failed: $cleanupError');
        }
      }
      _showMessage('Không thể lưu khoản chi: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Set<String> _effectiveMemberIds(List<_ExpenseMember> members) {
    if (_selectionTripId != null &&
        _selectionTripId != ref.read(currentTripIdProvider)) {
      _selectedMemberIds.clear();
      _selectionCustomized = false;
    }
    _selectionTripId = ref.read(currentTripIdProvider);
    if (!_selectionCustomized) {
      return members.map((member) => member.id).toSet();
    }
    return _selectedMemberIds;
  }

  Map<String, int>? _buildSplitDetails(
    List<_ExpenseMember> members,
    int amount,
  ) {
    if (!_isCustomSplit) {
      final baseAmount = amount ~/ members.length;
      var remainder = amount % members.length;
      return {
        for (final member in members)
          member.id: baseAmount + (remainder-- > 0 ? 1 : 0),
      };
    }
    final details = <String, int>{};
    for (final member in members) {
      final value = int.tryParse(
        _customSplitControllers[member.id]?.text.replaceAll('.', '') ?? '',
      );
      if (value == null || value < 0) return null;
      details[member.id] = value;
    }
    final total = details.values.fold<int>(0, (sum, value) => sum + value);
    return total == amount ? details : null;
  }

  List<_ExpenseMember> _membersFromTrip(
    List<TripMember> tripMembers,
    String? currentUserId,
  ) {
    final members = tripMembers
        .map(
          (member) =>
              _ExpenseMember(id: member.userId, name: member.displayName),
        )
        .toList();
    if (members.isNotEmpty) return members;
    if (currentUserId != null) {
      return [_ExpenseMember(id: currentUserId, name: 'Tôi')];
    }
    return MockTripData.members
        .map((member) => _ExpenseMember(id: member.id, name: member.name))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tripId = ref.watch(currentTripIdProvider) ?? 'demo-trip';
    final trip = ref.watch(currentTripProvider).asData?.value;
    final currentUser =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    final tripMembers =
        ref.watch(currentTripMembersProvider).asData?.value ?? const [];
    final members = _membersFromTrip(tripMembers, currentUser?.uid);
    final activeMember = members.where((item) => item.id == currentUser?.uid);
    final payer = activeMember.isNotEmpty ? activeMember.first : members.first;
    final targetBudget = trip?.targetBudget ?? MockTripData.totalTargetFund;
    final envelopeAsync = ref.watch(
      budgetEnvelopeStreamProvider(
        BudgetStreamParams(
          tripId: tripId,
          targetBudget: targetBudget,
          isHost: trip != null && trip.hostId == currentUser?.uid,
        ),
      ),
    );
    final envelopes = envelopeAsync.asData?.value ?? const <BudgetEnvelope>[];
    _selectedEnvelopeId ??= envelopes
        .where((envelope) => envelope.id == 'food')
        .firstOrNull
        ?.id;

    final selectedIds = _effectiveMemberIds(members);
    final selectedCount = members
        .where((m) => selectedIds.contains(m.id))
        .length;
    final perPerson = selectedCount == 0 ? 0 : _parsedAmount ~/ selectedCount;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text(
            'Hủy',
            style: TextStyle(color: AppColors.onPrimaryContainer),
          ),
        ),
        leadingWidth: 68,
        title: const Text('Thêm khoản chi'),
        actions: [
          TextButton(
            key: const Key('cashew_save_button'),
            onPressed: _isSaving
                ? null
                : () => _saveExpense(
                    tripId: tripId,
                    memberId: payer.id,
                    memberName: payer.name,
                    members: members,
                    envelopes: envelopes,
                  ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Lưu',
                    style: TextStyle(
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
          FilledButton.tonalIcon(
            onPressed: _isScanning ? null : _scanReceipt,
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.document_scanner_outlined, size: 20),
            label: Text(
              _isScanning
                  ? 'Đang nhận diện hóa đơn...'
                  : 'Chụp / chọn hóa đơn để quét OCR',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_receiptPath != null) ...[
            const SizedBox(height: 8),
            Text(
              'Đã đính kèm ảnh hóa đơn • OCR: ${MockTripData.formatVnd(_ocrDetectedAmount ?? 0)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 14),
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Số tiền (VNĐ)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                TextField(
                  key: const Key('cashew_amount_field'),
                  controller: _amountCtrl,
                  keyboardType: TextInputType.none,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  style: AppTheme.monoAmount(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                  ),
                ),
                Text(
                  MockTripData.formatVnd(_parsedAmount),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                CashewAmountKeypad(onKeyPressed: _onKeypadTap),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      key: const Key('cashew_key_+50k'),
                      label: const Text('+50k'),
                      onPressed: () => _addQuickAmount(50000),
                    ),
                    ActionChip(
                      key: const Key('cashew_key_+100k'),
                      label: const Text('+100k'),
                      onPressed: () => _addQuickAmount(100000),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppSectionHeader(title: 'Hũ ngân sách'),
          envelopeAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Text('Không tải được hũ ngân sách: $error'),
            data: (items) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                final selected = item.id == _selectedEnvelopeId;
                return ChoiceChip(
                  label: Text(item.name),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedEnvelopeId = item.id),
                  selectedColor: AppColors.primaryContainer,
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          AppInsetCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung khoản chi',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Divider(indent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (không bắt buộc)',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Divider(indent: 16),
                ListTile(
                  title: const Text('Người trả'),
                  trailing: Text(
                    payer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppSectionHeader(title: 'Nguồn tiền'),
          AppSegmentedControl(
            segments: const ['Quỹ chung', 'Chi hộ / ứng trước'],
            selectedIndex: _paymentSourceIndex,
            onChanged: (index) => setState(() => _paymentSourceIndex = index),
          ),
          const SizedBox(height: 16),
          const AppSectionHeader(title: 'Chia khoản chi'),
          AppSegmentedControl(
            segments: const ['Chia đều', 'Tùy chỉnh'],
            selectedIndex: _isCustomSplit ? 1 : 0,
            onChanged: (index) {
              setState(() {
                _isCustomSplit = index == 1;
                final selected = members
                    .where((member) => selectedIds.contains(member.id))
                    .toList();
                if (_isCustomSplit && selected.isNotEmpty) {
                  final base = _parsedAmount ~/ selected.length;
                  var remainder = _parsedAmount % selected.length;
                  for (final member in selected) {
                    _customSplitControllers
                        .putIfAbsent(member.id, () => TextEditingController())
                        .text = (base + (remainder-- > 0 ? 1 : 0))
                        .toString();
                  }
                }
              });
            },
          ),
          const SizedBox(height: 10),
          AppInsetCard(
            child: Column(
              children: [
                for (var index = 0; index < members.length; index++)
                  Column(
                    children: [
                      CheckboxListTile(
                        value: selectedIds.contains(members[index].id),
                        activeColor: AppColors.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(members[index].name),
                        secondary: _isCustomSplit
                            ? SizedBox(
                                width: 100,
                                child: TextField(
                                  key: Key('cashew_split_${members[index].id}'),
                                  controller: _customSplitControllers
                                      .putIfAbsent(
                                        members[index].id,
                                        () => TextEditingController(
                                          text: perPerson.toString(),
                                        ),
                                      ),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.end,
                                  decoration: const InputDecoration(
                                    suffixText: 'đ',
                                    isDense: true,
                                  ),
                                ),
                              )
                            : Text(
                                selectedIds.contains(members[index].id)
                                    ? MockTripData.formatVnd(perPerson)
                                    : '0đ',
                                style: AppTheme.monoAmount(fontSize: 14),
                              ),
                        onChanged: (selected) => setState(() {
                          _selectionCustomized = true;
                          if (selected == true) {
                            _selectedMemberIds.add(members[index].id);
                          } else {
                            _selectedMemberIds.remove(members[index].id);
                          }
                        }),
                      ),
                      if (index < members.length - 1) const Divider(indent: 52),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseMember {
  const _ExpenseMember({required this.id, required this.name});

  final String id;
  final String name;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
