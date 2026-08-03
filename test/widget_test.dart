// 로그인 화면이 정상적으로 그려지는지 확인하는 기본 테스트.

import 'package:flutter_test/flutter_test.dart';

import 'package:cherrishbomb_app/main.dart';

void main() {
  testWidgets('로그인 화면 스모크 테스트', (WidgetTester tester) async {
    // 앱을 띄운다.
    await tester.pumpWidget(const CherrishbombApp());

    // 로그인 화면의 요소들이 보이는지 확인.
    expect(find.text('보호자 로그인'), findsOneWidget);
    expect(find.text('카카오로 로그인'), findsOneWidget);
    expect(find.text('구글로 로그인'), findsOneWidget);
  });
}
