import 'package:flutter/services.dart';

/// 숫자만 입력받아 지정한 자리마다 '-'를 자동으로 넣어주는 포매터.
/// 예) groups=[3,4,4] → 01012345678 을 010-1234-5678 로,
///     groups=[4,2,2] → 20000101 을 2000-01-01 로 자동 변환.
class DashFormatter extends TextInputFormatter {
  final List<int> groups;
  DashFormatter(this.groups);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 숫자만 남기고
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final maxLen = groups.reduce((a, b) => a + b);
    final trimmed =
        digits.length > maxLen ? digits.substring(0, maxLen) : digits;

    // 그룹 단위로 잘라서 '-'로 연결
    final buffer = StringBuffer();
    int idx = 0;
    for (int i = 0; i < groups.length && idx < trimmed.length; i++) {
      if (i > 0) buffer.write('-');
      final end = (idx + groups[i]).clamp(0, trimmed.length);
      buffer.write(trimmed.substring(idx, end));
      idx = end;
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length), // 커서 맨 뒤로
    );
  }
}

/// MAC 주소 자동 형식 포매터.
/// 16진수(0-9, A-F)만 받고 대문자로 바꾼 뒤, 2자리마다 ':'를 넣어준다.
/// 예) aabbccddeeff → AA:BB:CC:DD:EE:FF
class MacFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 16진수만 남기고 대문자화, 최대 12자(6쌍)
    var hex = newValue.text.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
    if (hex.length > 12) hex = hex.substring(0, 12);

    // 2자리마다 ':' 삽입
    final buffer = StringBuffer();
    for (int i = 0; i < hex.length; i++) {
      if (i > 0 && i % 2 == 0) buffer.write(':');
      buffer.write(hex[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length), // 커서 맨 뒤로
    );
  }
}
