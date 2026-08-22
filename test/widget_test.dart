// 로그인 화면이 정상적으로 그려지는지 확인하는 스모크 테스트.
// 앱 전체(CherrishbombApp)는 go_router로 스플래시부터 시작하고
// 스플래시가 secure storage(토큰)를 읽어 테스트 환경에서 로그인까지 못 가므로,
// LoginPage를 직접 띄워 화면 요소만 검증한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cherrishbomb_app/screens/login_page.dart';

void main() {
  testWidgets('로그인 화면 스모크 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('보호자 로그인'), findsOneWidget);
    expect(find.text('카카오로 로그인'), findsOneWidget);
    expect(find.text('구글로 로그인'), findsOneWidget);
  });
}
