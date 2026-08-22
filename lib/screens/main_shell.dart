import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemNavigator

import 'home_page.dart';
import 'activity_log_page.dart';
import 'device_page.dart';
import 'settings_page.dart';

/// 로그인 후 메인 화면. 하단 탭으로 4개 화면을 전환한다.
/// 탭마다 독립 Navigator를 두어, 탭 안에서 상세 화면(연락망·건강정보·알림함)을
/// 열어도 하단 탭이 계속 유지되도록 한다. (#23: 하단 탭 지속 + Scaffold 구조 개선)
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0; // 현재 선택된 탭
  final _navKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());
  final Set<int> _loaded = {0}; // 방문한 탭만 빌드 (lazy)

  Widget _rootFor(int i) {
    switch (i) {
      case 0:
        return const HomePage();
      case 1:
        return const ActivityLogPage();
      case 2:
        return const DevicePage();
      default:
        return const SettingsPage();
    }
  }

  // 탭 전용 Navigator. 탭 안 push는 이 Navigator를 타서 하단 탭 밖으로 안 나감.
  Widget _tabNavigator(int i) {
    return Navigator(
      key: _navKeys[i],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _rootFor(i)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final nav = _navKeys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop(); // 탭 안 상세 화면 닫기 (하단 탭 유지)
        } else if (_index != 0) {
          setState(() => _index = 0); // 그 외 탭 → 홈 탭으로
        } else {
          SystemNavigator.pop(); // 홈 탭 + 더 없음 → 앱 종료
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: List.generate(4, (i) => _loaded.contains(i) ? _tabNavigator(i) : const SizedBox.shrink()),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            if (i == _index) {
              // 같은 탭 재선택 → 그 탭의 첫 화면으로
              _navKeys[i].currentState?.popUntil((r) => r.isFirst);
            } else {
              setState(() {
                _index = i;
                _loaded.add(i);
              });
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
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
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '설정'),
          ],
        ),
      ),
    );
  }
}
