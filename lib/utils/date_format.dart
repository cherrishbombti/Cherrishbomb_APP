// 날짜 포맷 공용 유틸 (화면·서비스 어디서나 재사용).
// 서비스 계층에서도 쓰므로 flutter UI에 의존하지 않는 순수 함수로 둔다.

String pad2(int n) => n.toString().padLeft(2, '0');

/// 'YYYY-MM-DD' (서버 전송·필터 표시용)
String ymd(DateTime d) => '${d.year}-${pad2(d.month)}-${pad2(d.day)}';

/// 'MM-DD HH:mm' (로그 발생 시각 표시용)
String mdHm(DateTime d) =>
    '${pad2(d.month)}-${pad2(d.day)} ${pad2(d.hour)}:${pad2(d.minute)}';
