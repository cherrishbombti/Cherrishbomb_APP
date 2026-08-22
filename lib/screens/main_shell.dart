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

  // 실제로 방문한 탭만 빌드한다. (C1: IndexedStack이 4개 화면을
  // 한 번에 빌드해 모든 initState가 동시에 실행되던 문제 해결)
  // 시작 탭(홈)만 미리 로드하고, 나머지는 처음 눌렀을 때 로드.
  final Set<int> _loaded = {0};

  Widget _pageAt(int i) {
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

  @override
  Widget build(BuildContext context) {
    // 뒤로가기 처리: 홈 탭(0)에서만 앱 종료 허용.
    // 다른 탭에서 뒤로가기를 누르면 앱을 끄지 않고 홈 탭으로 돌아간다.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // 이미 pop됐으면(홈 탭) 그대로 종료
        setState(() => _index = 0); // 그 외 탭 → 홈 탭으로
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          // 방문 전 탭은 빈 위젯, 방문 후엔 실제 화면 (한 번 로드되면 유지)
          children: List.generate(4, (i) => _loaded.contains(i) ? _pageAt(i) : const SizedBox.shrink()),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() {
            _index = i;
            _loaded.add(i); // 처음 방문하는 탭이면 로드 목록에 추가
          }),
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
