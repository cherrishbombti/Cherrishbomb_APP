import 'package:flutter/material.dart';

// 앱의 시작점. 여기서 앱 전체를 실행한다.
void main() {
  runApp(const CherrishbombApp());
}

// 앱의 뿌리(root) 위젯. 화면이 바뀌지 않는 껍데기라 StatelessWidget.
class CherrishbombApp extends StatelessWidget {
  const CherrishbombApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '낙상감지 핫 라인 시스템',
      // 앱 전체의 기본 색/폰트 테마
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // 앱을 켜면 처음 보이는 화면
      home: const LoginPage(),
    );
  }
}

// 로그인 화면. 아직 바뀌는 값이 없어서 StatelessWidget.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SafeArea: 노치·상태바 같은 영역을 피해서 안전하게 그려줌
      body: SafeArea(
        child: Padding(
          // 화면 좌우에 24픽셀 여백
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            // 세로 가운데 정렬
            mainAxisAlignment: MainAxisAlignment.center,
            // 가로로 꽉 채우기 (버튼이 화면 너비만큼 늘어나게)
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 앱 아이콘 느낌의 아이콘
              const Icon(Icons.favorite, size: 72, color: Colors.deepPurple),
              const SizedBox(height: 16), // 위젯 사이 세로 간격
              // 앱 이름
              const Text(
                '낙상감지 핫 라인 시스템',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // 안내 문구
              const Text(
                '보호자 로그인',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              // 카카오 로그인 버튼 → 홈 화면으로 이동
              FilledButton(
                onPressed: () {
                  // Navigator.push: 새 화면을 현재 화면 "위에" 쌓아 올린다.
                  // context는 "지금 이 위젯이 화면 어디에 있는지" 정보.
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
                child: const Text('카카오로 로그인'),
              ),
              const SizedBox(height: 12),
              // 구글 로그인 버튼
              OutlinedButton(
                onPressed: () {
                  debugPrint('구글 로그인 버튼 눌림');
                },
                child: const Text('구글로 로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 임시 홈 화면. 로그인 성공 후 보여줄 화면 (지금은 뼈대만).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        // 뒤로가기 버튼은 Navigator가 자동으로 만들어 줌
      ),
      body: const Center(
        child: Text('로그인 성공! 홈 화면입니다.', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
