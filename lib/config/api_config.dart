/// 서버 주소를 한 곳에서 관리.
class ApiConfig {
  // 실행 환경마다 주소가 다름:
  //  - 크롬 / iOS 시뮬레이터 : localhost
  //  - 실제 아이폰          : 맥의 IP (예: http://192.168.0.5:8080)
  //  - 안드로이드 에뮬레이터 : http://10.0.2.2:8080
  static const String baseUrl = 'http://localhost:8080';
}
