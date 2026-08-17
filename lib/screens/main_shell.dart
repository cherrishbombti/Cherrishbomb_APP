import 'package:flutter/material.dart';
import 'home_page.dart';
import 'activity_log_page.dart';
import 'device_page.dart';
import 'settings_page.dart';

/// 로그인 후 메인 화면. 하단 탭으로 4개 화면을 전환한다.
/// 홈 / 활동 로그 / 기기 관리 / 설정
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0; // 현재 선택된 탭

  // 각 탭에 해당하는 화면들 (IndexedStack이라 탭 전환해도 상태 유지)
  static const _pages = [
    HomePage(),
    ActivityLogPage(),
    DevicePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: '활동 로그',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: '기기 관리',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
