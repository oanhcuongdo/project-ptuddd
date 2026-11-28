import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../utils/cashew_calculator.dart';

/// Màn hình Thêm hóa đơn mới — nâng cấp từ Stitch (th_m_h_a_n_m_i):
/// Bổ sung nút Quét hóa đơn Camera OCR (ML Kit) và thanh phím máy tính nhanh kiểu Cashew.
class AddExpenseOcrScreen extends StatefulWidget {
  const AddExpenseOcrScreen({super.key});

  @override
  State<AddExpenseOcrScreen> createState() => _AddExpenseOcrScreenState();
}

class _AddExpenseOcrScreenState extends State<AddExpenseOcrScreen> {
  final _amountCtrl = TextEditingController(text: '680000');
  final _titleCtrl = TextEditingController(text: 'Ăn tối Lẩu Gà Lá É');
  int _selectedCat = 0;
  int _splitMode = 0; // 0: Chia đều | 1: Tùy chỉnh
  final _cats = const ['Ăn uống', 'Di chuyển', 'Lưu trú', 'Vé tham quan'];
  final _checked = [true, true, true, true];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  int get _parsedAmount {
    final evaluated = CashewCalculator.evaluate(_amountCtrl.text);
    if (evaluated != null && evaluated >= 0) {
      return evaluated.round();
    }
    return int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
  }

  void _onKeypadTap(String op) {
    if (op == '+50k' || op == '+100k') {
      final delta = op == '+50k' ? 50000 : 100000;
      setState(() => _amountCtrl.text = '${_parsedAmount + delta}');
      return;
    }
    if (op == '=') {
      final evaluated = CashewCalculator.evaluate(_amountCtrl.text);
      if (evaluated == null || evaluated < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biểu thức tính tiền không hợp lệ hoặc chia cho 0.'),
          ),
        );
        return;
      }
      setState(() => _amountCtrl.text = evaluated.round().toString());
      return;
    }
    setState(() {
      _amountCtrl.text = CashewCalculator.appendOperator(_amountCtrl.text, op);
      _amountCtrl.selection = TextSelection.collapsed(
        offset: _amountCtrl.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _checked.where((e) => e).length;
    final perPerson = activeCount > 0 ? (_parsedAmount / activeCount).round() : 0;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('Hủy', style: TextStyle(color: AppColors.onPrimaryContainer)),
        ),
        leadingWidth: 68,
        title: const Text('Thêm hóa đơn'),
        actions: [
          TextButton(
            key: const Key('cashew_save_button'),
            onPressed: () {
              // TODO(Module 4): Lưu Expense vào Firestore & cập nhật Hũ ngân sách
              context.pop();
            },
            child: const Text(
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
          // Nút Quét hóa đơn tự động Camera OCR (ML Kit)
          FilledButton.tonalIcon(
            onPressed: () {
              // TODO(Module 4): Mở Camera + google_mlkit_text_recognition bóc tách tổng tiền
              setState(() => _amountCtrl.text = '680000');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('TODO(Module 4): Mở Camera OCR tự đọc tổng tiền hóa đơn'),
                ),
              );
            },
            icon: const Icon(Icons.document_scanner_outlined, size: 20),
            label: const Text('Quét hóa đơn tự động (Camera OCR)'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),

          // Ô nhập số tiền lớn + thanh phím máy tính nhanh kiểu Cashew
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Số tiền (VNĐ)',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                TextField(
                  key: const Key('cashew_amount_field'),
                  controller: _amountCtrl,
                  keyboardType: TextInputType.text,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  style: AppTheme.monoAmount(fontSize: 30, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
                const Divider(),
                const SizedBox(height: 8),
                // Thanh phép tính nhanh Cashew
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: ['+', '−', '×', '÷', '=', '+50k', '+100k']
                      .map((op) => ActionChip(
                            key: Key('cashew_key_$op'),
                            label: Text(op),
                            backgroundColor: op == '='
                                ? AppColors.primaryContainer
                                : AppColors.surfaceContainerLow,
                            side: const BorderSide(color: AppColors.outlineVariantSoft),
                            onPressed: () => _onKeypadTap(op),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Danh mục
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final active = _selectedCat == index;
                return ChoiceChip(
                  label: Text(_cats[index]),
                  selected: active,
                  onSelected: (_) => setState(() => _selectedCat = index),
                  selectedColor: AppColors.primaryContainer,
                  backgroundColor: AppColors.surfaceContainer,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Chi tiết khoản chi
          AppInsetCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Text('Khoản chi', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _titleCtrl,
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: AppColors.onSurfaceVariant),
                          decoration: const InputDecoration(border: InputBorder.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(indent: 16),
                const ListTile(
                  title: Text('Người trả'),
                  trailing: Text(
                    'Đỗ Đình An',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Chia tiền 4 thành viên
          AppSegmentedControl(
            segments: const ['Chia đều', 'Tùy chỉnh'],
            selectedIndex: _splitMode,
            onChanged: (i) => setState(() => _splitMode = i),
          ),
          const SizedBox(height: 10),
          AppInsetCard(
            child: Column(
              children: List.generate(MockTripData.members.length, (i) {
                final m = MockTripData.members[i];
                return Column(
                  children: [
                    CheckboxListTile(
                      value: _checked[i],
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(m.name),
                      secondary: Text(
                        _checked[i] ? MockTripData.formatVnd(perPerson) : '0đ',
                        style: AppTheme.monoAmount(fontSize: 14),
                      ),
                      onChanged: (v) => setState(() => _checked[i] = v ?? false),
                    ),
                    if (i < MockTripData.members.length - 1) const Divider(indent: 52),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
