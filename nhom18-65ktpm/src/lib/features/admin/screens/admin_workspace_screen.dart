import 'package:flutter/material.dart';

import '../../../core/widgets/hci_components.dart';
import 'admin_management_screen.dart';
import 'admin_statistics_screen.dart';

class AdminWorkspaceScreen extends StatefulWidget {
  const AdminWorkspaceScreen({super.key});

  @override
  State<AdminWorkspaceScreen> createState() => _AdminWorkspaceScreenState();
}

class _AdminWorkspaceScreenState extends State<AdminWorkspaceScreen> {
  int _tab = 0;
  String? _managementStatusFilter;
  int _managementVersion = 0;

  void _openPendingReview() {
    setState(() {
      _managementStatusFilter = 'pending';
      _managementVersion++;
      _tab = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Quản lý hệ thống' : 'Thống kê hệ thống'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => confirmAndSignOut(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _tab == 0
          ? AdminManagementScreen(
              key: ValueKey(_managementVersion),
              embedded: true,
              initialStatusFilter: _managementStatusFilter,
            )
          : AdminStatisticsScreen(
              embedded: true,
              onOpenPending: _openPendingReview,
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Quản lý',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
        ],
      ),
    );
  }
}
