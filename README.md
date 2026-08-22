# Cherrishbomb App (보호자 앱)

낙상감지 시스템의 **보호자 전용 모바일 앱**  기존 웹의 보호자 기능을 앱으로 이관.
백엔드(Spring Boot)는 기존 서버를 그대로 사용한다.

## 기술 스택

- Flutter/ Dart
- dio (HTTP 통신), flutter_secure_storage (토큰 보관)
- flutter_web_auth_2 (소셜 로그인), url_launcher (전화 걸기)

## 폴더 구조

```
lib/
├── main.dart                # 앱 진입점 + MaterialApp (라우팅)
├── core/
│   └── app_globals.dart     # 전역 navigatorKey
├── config/
│   └── api_config.dart      # 서버 baseUrl 
├── models/                  # 서버 응답 데이터 모델
│   ├── ward_summary.dart
│   └── ward_sensor.dart
├── services/                # 통신·비즈니스 로직
│   ├── api_client.dart      # 공용 dio 클라이언트 
│   ├── token_storage.dart   # 토큰 저장/조회/삭제
│   ├── auth_service.dart    # 소셜 로그인 / 로그아웃
│   └── ward_service.dart    # 피보호자 등록·요약·센서 API
├── screens/                 # 화면
│   ├── splash_page.dart     # 시작 시 토큰 확인 → 홈/로그인 분기
│   ├── login_page.dart      # 소셜 로그인
│   ├── ward_register_page.dart  # 피보호자 등록 폼
│   └── home_page.dart       # 보호자 모드(상태 요약 + 센서)
├── widgets/
│   └── logout_button.dart   # 공용 로그아웃 버튼
└── utils/
    └── input_formatters.dart  # 전화/생년월일/MAC 입력 자동 형식
```


## 실행 방법

### 준비
```bash
flutter pub get
```

### iOS 시뮬레이터
`flutter run`은 현재 Xcode 버전의 codesign 이슈로 실패하므로 **Xcode + attach** 방식을 사용한다.
1. `open ios/Runner.xcworkspace` → Signing Team을 본인 Apple ID로 설정 → ▶ 실행
2. Xcode 콘솔에서 Dart VM 주소 확인
3. `flutter attach --debug-url=<주소>` → hot reload(`r`) 사용

### 크롬 (빠른 개발용)
```bash
flutter run -d chrome
```

## 백엔드 연동

- 소셜 로그인(OAuth)은 백엔드가 처리 후 `cherrishbomb://login`으로 앱에 복귀 (state=app)
- 인증은 JWT 토큰 (요청 시 `Authorization: Bearer` 자동 첨부)

## 진행 현황 (이슈)

- [x] #1 로그인 화면 UI
- [x] #2 API 통신 레이어
- [x] #3 소셜 로그인(OAuth) + 로그아웃
- [x] #4 피보호자 등록 화면
- [x] #5 홈(보호자 모드) — 상태 요약·센서 (일부 mock, 백엔드 연동 대기)
- [ ] #6 비상 연락처 관리

## 알려진 제약

- 배터리·신호·위치, 센서(진동/레이더/열화상) 상태는 백엔드 미제공이라 임시 mock 표시 (TODO 주석).
- 활동 시간 등 미구현 항목은 화면에서 제외.
