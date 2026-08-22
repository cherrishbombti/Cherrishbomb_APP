/// 서버 주소를 한 곳에서 관리.
class ApiConfig {
  // 주소는 코드에 박지 않고 실행 시 바깥에서 주입한다.
  //   flutter run --dart-define=API_BASE_URL=https://api.example.com
  // 아무것도 안 주면 개발용 기본값(localhost) 사용.
  //
  // 참고 (실행 환경별 주소):
  //   - 크롬 / iOS 시뮬레이터 : http://localhost:8080
  //   - 실제 아이폰          : http://<맥 IP>:8080  (개발 시)
  //   - 안드로이드 에뮬레이터 : http://10.0.2.2:8080
  //   - 배포                : https://<서버 도메인>
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');
}
