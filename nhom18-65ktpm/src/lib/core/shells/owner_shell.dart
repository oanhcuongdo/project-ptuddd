import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/owner/data/owner_shop_repository.dart';
import '../../features/owner/screens/shop_editor_screen.dart';
import '../../features/owner/widgets/shop_open_status_card.dart';
import '../../features/sos/widgets/sos_inbox.dart';
import '../../models/shop.dart';
import '../push_service.dart';
import '../theme.dart';
import '../widgets/hci_components.dart';

/// Phân hệ Chủ tiệm: UC-09, UC-10, UC-11 (quản lý tiệm) & UC-12 (hộp thư SOS).
class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  final _repository = OwnerShopRepository();
  late Future<List<Shop>> _shops;
  StreamSubscription<String>? _pushSubscription;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _shops = _repository.myShops();
    if (PushService.takeInitialSosId() != null) _tab = 1;
    _pushSubscription = PushService.sosAlerts.listen((_) {
      if (mounted) setState(() => _tab = 1);
    });
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    final future = _repository.myShops();
    setState(() {
      _shops = future;
    });
    try {
      await future;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tải lại được danh sách tiệm.')),
        );
      }
    }
  }

  Future<void> _openForm([Shop? shop]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ShopEditorScreen(shop: shop)),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shop == null
              ? 'Đã đăng ký tiệm. Vui lòng chờ Admin phê duyệt.'
              : 'Đã cập nhật thông tin tiệm.',
        ),
      ),
    );
    await _reload();
  }

  String _clock(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;

  Widget _metaRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.inkPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shopCard(Shop shop) {
    final isGas = shop.category == 'gas_station';
    final accent = isGas ? AppColors.primary : AppColors.motoOrange;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: accent.withValues(alpha: 0.22)),
                  ),
                  child: Icon(
                    isGas
                        ? Icons.local_gas_station_rounded
                        : Icons.build_rounded,
                    size: 20,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        isGas ? 'Cây xăng' : 'Tiệm sửa xe',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                buildStatusBadge(shop.status),
              ],
            ),
            const SizedBox(height: 12),
            _metaRow(Icons.location_on_outlined, shop.address, AppColors.sosRed),
            _metaRow(Icons.phone_outlined, 'Hotline: ${shop.phone}', AppColors.success),
            _metaRow(
              Icons.schedule_rounded,
              '${_clock(shop.openTime)} – ${_clock(shop.closeTime)} · '
              'Đánh giá ${shop.rating.toStringAsFixed(1)}/5 (${shop.reviewCount})',
              AppColors.primary,
            ),
            if (shop.imageUrl != null && shop.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    shop.imageUrl!,
                    height: 155,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Text('Không hiển thị được ảnh tiệm.'),
                  ),
                ),
              ),
            if (shop.status == 'rejected' &&
                (shop.rejectionReason?.trim().isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: FeedbackBanner(
                  title: 'Lý do từ chối',
                  message: shop.rejectionReason!,
                  tone: FeedbackTone.error,
                ),
              ),
            if (shop.status == 'approved') ...[
              const SizedBox(height: 8),
              ShopOpenStatusCard(shop: shop, compact: true, onChanged: _reload),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: shop.status == 'banned'
                    ? null
                    : () => _openForm(shop),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Chỉnh sửa'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopsTab() {
    return FutureBuilder<List<Shop>>(
      future: _shops,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyStateCard(
            icon: Icons.wifi_off_rounded,
            title: 'Không tải được danh sách tiệm',
            message: 'Kiểm tra kết nối mạng và quyền truy cập rồi thử lại.',
            accentColor: AppColors.warning,
            action: FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          );
        }
        final shops = snapshot.data ?? <Shop>[];
        return RefreshIndicator(
          onRefresh: _reload,
          child: shops.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 60),
                    EmptyStateCard(
                      icon: Icons.storefront_rounded,
                      title: 'Chưa có cơ sở nào',
                      message:
                          'Đăng ký tiệm sửa xe hoặc cây xăng đầu tiên để hiển thị trên bản đồ cho khách hàng.',
                      accentColor: AppColors.motoOrange,
                      action: FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add_business_rounded),
                        label: const Text('Đăng ký tiệm ngay'),
                      ),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: shops.map(_shopCard).toList(),
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Quản lý tiệm' : 'Yêu cầu cứu hộ SOS'),
        actions: [
          if (_tab == 0)
            IconButton(
              tooltip: 'Làm mới',
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => confirmAndSignOut(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_business),
              label: const Text('Đăng ký tiệm'),
            )
          : null,
      body: _tab == 0
          ? _buildShopsTab()
          : SosInbox(onCaseFinished: _reload),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront),
            label: 'Tiệm của tôi',
          ),
          NavigationDestination(
            icon: Icon(Icons.sos),
            label: 'Cứu hộ SOS',
          ),
        ],
      ),
    );
  }
}
