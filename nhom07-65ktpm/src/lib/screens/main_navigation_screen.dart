import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'sleep_management/sleep_goal_screen.dart';
import 'power_nap/power_nap_screen.dart';
import 'statistics/statistics_screen.dart';
import 'ai_assistant/ai_assistant_screen.dart';
import 'sleep_tips/sleep_tips_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateTab: _onTabSelected),
      const SleepGoalScreen(),
      const PowerNapScreen(),
      const StatisticsScreen(),
      const AIAssistantScreen(),
    ];

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1E293B)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.bedtime, size: 40, color: Color(0xFF38BDF8)),
                  SizedBox(height: 10),
                  Text('DCSleep App', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Nhóm 07 - Lớp 65KTPM', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Trang chủ'),
              onTap: () {
                Navigator.pop(context);
                _onTabSelected(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bedtime_outlined),
              title: const Text('Mục tiêu giấc ngủ'),
              onTap: () {
                Navigator.pop(context);
                _onTabSelected(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on_outlined),
              title: const Text('Giấc ngủ ngắn (Power Nap)'),
              onTap: () {
                Navigator.pop(context);
                _onTabSelected(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Thống kê & Tiến độ'),
              onTap: () {
                Navigator.pop(context);
                _onTabSelected(3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy_outlined),
              title: const Text('Trợ lý AI Sleep Assistant'),
              onTap: () {
                Navigator.pop(context);
                _onTabSelected(4);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Thư viện kiến thức giấc ngủ'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepTipsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Cài đặt & Quyền riêng tư'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bedtime_outlined),
            activeIcon: Icon(Icons.bedtime),
            label: 'Mục tiêu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on_outlined),
            activeIcon: Icon(Icons.flash_on),
            label: 'Power Nap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'Trợ lý AI',
          ),
        ],
      ),
    );
  }
}
