import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 회원가입용 검증 텍스트 필드. (required / 형식(pattern) / 추가검증(extraCheck))
class RegTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final String? pattern;
  final String? patternMsg;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String value)? extraCheck;

  const RegTextField({
    super.key,
    required this.controller,
    required this.label,
    this.required = false,
    this.pattern,
    this.patternMsg,
    this.keyboardType,
    this.inputFormatters,
    this.extraCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          final v = (value ?? '').trim();
          if (required && v.isEmpty) return '$label 입력해주세요';
          if (pattern != null && v.isNotEmpty && !RegExp(pattern!).hasMatch(v)) {
            return patternMsg;
          }
          if (extraCheck != null && v.isNotEmpty) {
            final msg = extraCheck!(v);
            if (msg != null) return msg;
          }
          return null;
        },
      ),
    );
  }
}
