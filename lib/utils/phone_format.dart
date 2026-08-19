// 전화번호 포맷 유틸.
// 팀 합의 규칙: 저장·전송은 숫자만, 화면 표시할 때만 하이픈.

/// 숫자만 남긴다 (하이픈 등 제거). 서버 전송·전화걸기용.
String phoneDigits(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');

/// 저장된 숫자 전화번호를 표시용으로 하이픈을 넣어 반환.
/// 11자리(010…) → 3-4-4, 10자리 → 3-3-4, 그 외는 원본 그대로.
String formatPhone(String raw) {
  final d = phoneDigits(raw);
  if (d.length == 11) {
    return '${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7)}';
  }
  if (d.length == 10) {
    return '${d.substring(0, 3)}-${d.substring(3, 6)}-${d.substring(6)}';
  }
  return raw;
}
