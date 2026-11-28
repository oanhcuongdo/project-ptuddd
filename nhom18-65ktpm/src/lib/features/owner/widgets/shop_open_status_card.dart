import 'package:flutter/material.dart';

import '../../../core/supabase_client.dart';
import '../../../core/supabase_errors.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/hci_components.dart';
import '../../../models/shop.dart';
import '../../../repositories/auth_repository.dart';

class ShopOpenStatusCard extends StatefulWidget {
  const ShopOpenStatusCard({
    super.key,
    required this.shop,
    this.onChanged,
    this.compact = false,
  });

  final Shop shop;
  final VoidCallback? onChanged;
  final bool compact;

  @override
  State<ShopOpenStatusCard> createState() => _ShopOpenStatusCardState();
}

class _ShopOpenStatusCardState extends State<ShopOpenStatusCard> {
  late bool _isOpen;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.shop.isOpen;
  }

  @override
  void didUpdateWidget(covariant ShopOpenStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shop.id != widget.shop.id ||
        oldWidget.shop.isOpen != widget.shop.isOpen) {
      _isOpen = widget.shop.isOpen;
    }
  }

  String _statusText(String status) => switch (status) {
    'approved' => 'Đã duyệt',
    'pending' => 'Chờ duyệt',
    'rejected' => 'Bị từ chối',
    'banned' => 'Đã khóa',
    _ => status,
  };

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setOpen(bool value) async {
    if (_busy || widget.shop.status != 'approved') {
      return;
    }

    setState(() => _busy = true);
    try {
      await guardSupabase(() async {
        final ownerId = supabase.auth.currentUser?.id;
        if (ownerId == null) {
          throw const AppException('Vui lòng đăng nhập lại.');
        }

        final shop = await supabase
            .from('shops')
            .select('id,owner_id,status,is_open')
            .eq('id', widget.shop.id)
            .eq('owner_id', ownerId)
            .maybeSingle();

        if (shop == null) {
          throw const AppException('Không tìm thấy tiệm thuộc tài khoản của bạn.');
        }
        if (shop['status'] != 'approved') {
          throw const AppException('Tiệm chưa được Admin phê duyệt.');
        }

        final oldValue = shop['is_open'] == true;
        if (!value && oldValue) {
          final active = await supabase
              .from('sos_requests')
              .select('id')
              .eq('accepted_shop_id', widget.shop.id)
              .eq('status', 'accepted')
              .limit(1);
          if (active.isNotEmpty) {
            throw const AppException(
              'Vui lòng hoàn thành ca cứu hộ đang xử lý trước khi tạm đóng cửa.',
            );
          }
        }

        if (oldValue == value) {
          if (mounted) setState(() => _isOpen = oldValue);
          _showMessage('Trạng thái tiệm đã được cập nhật trước đó.');
          return;
        }

        final updated = await supabase
            .from('shops')
            .update({'is_open': value})
            .eq('id', widget.shop.id)
            .eq('owner_id', ownerId)
            .eq('status', 'approved')
            .eq('is_open', oldValue)
            .select('is_open')
            .maybeSingle();

        if (updated == null) {
          throw const AppException(
            'Không cập nhật được trạng thái. Hãy tải lại tiệm.',
          );
        }

        if (!mounted) return;
        setState(() => _isOpen = updated['is_open'] == true);
        _showMessage(_isOpen ? 'Tiệm đã mở cửa.' : 'Tiệm đã tạm đóng cửa.');
        widget.onChanged?.call();
      });
    } on AppException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final approved = widget.shop.status == 'approved';
    final toggle = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _isOpen ? AppColors.successBg : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isOpen
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.success,
            value: _isOpen,
            title: Row(
              children: [
                LiveStatusDot(
                  color: _isOpen ? AppColors.success : AppColors.inkMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  _isOpen ? 'Đang mở cửa' : 'Tạm đóng cửa',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _isOpen
                        ? const Color(0xFF047857)
                        : AppColors.inkPrimary,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              approved
                  ? 'Trạng thái này ảnh hưởng đến việc hiển thị tiệm cho khách.'
                  : 'Chỉ được bật/tắt khi tiệm đã được duyệt.',
              style: const TextStyle(fontSize: 12),
            ),
            onChanged: approved && !_busy ? _setOpen : null,
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: LinearProgressIndicator(minHeight: 3),
            ),
        ],
      ),
    );
    if (widget.compact) return toggle;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.shop.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(_statusText(widget.shop.status))),
              ],
            ),
            const SizedBox(height: 8),
            toggle,
          ],
        ),
      ),
    );
  }
}
