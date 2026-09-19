/// 서버 주소를 한 곳에서 관리.
class ApiConfig {
  // 주소는 코드에 박지 않고 실행 시 바깥에서 주입한다.
  //   flutter run --dart-define=API_BASE_URL=https://api.example.com
  // 아무것도 안 주면 아래 기본값(배포 HTTPS 도메인)을 사용한다.
  //
  // 참고 (로컬 개발 시 주입할 주소 예시):
  //   - 크롬 / iOS 시뮬레이터 : http://localhost:8080
  //   - 실제 아이폰          : http://<맥 IP>:8080
  //   - 안드로이드 에뮬레이터 : http://10.0.2.2:8080
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://cherry-fall.duckdns.org');
}
