import 'package:flutter/material.dart';
import '../utils/input_formatters.dart';
import 'reg_text_field.dart';

/// STEP1 — 보호자 정보 (이름·연락처·관계)
class RegStep1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController relationship;
  const RegStep1({
    super.key,
    required this.formKey,
    required this.name,
    required this.phone,
    required this.relationship,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegTextField(controller: name, label: '이름', required: true),
          RegTextField(
            controller: phone,
            label: '연락처 (010-XXXX-XXXX)',
            required: true,
            inputFormatters: [DashFormatter([3, 4, 4])],
            pattern: r'^010-\d{4}-\d{4}$',
            patternMsg: '전화번호 형식이 올바르지 않습니다.',
          ),
          RegTextField(
              controller: relationship,
              label: '피보호자와의 관계 (예: 아들, 딸)',
              required: true),
        ],
      ),
    );
  }
}

/// STEP2 — 피보호자 정보 (이름·주소·연락처·기저질환·MAC)
class RegStep2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController address;
  final TextEditingController phone;
  final TextEditingController disease;
  final TextEditingController deviceMac;
  const RegStep2({
    super.key,
    required this.formKey,
    required this.name,
    required this.address,
    required this.phone,
    required this.disease,
    required this.deviceMac,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegTextField(controller: name, label: '이름', required: true),
          RegTextField(controller: address, label: '주소', required: true),
          RegTextField(
            controller: phone,
            label: '연락처 (010-XXXX-XXXX)',
            required: true,
            inputFormatters: [DashFormatter([3, 4, 4])],
            pattern: r'^010-\d{4}-\d{4}$',
            patternMsg: '전화번호 형식이 올바르지 않습니다.',
          ),
          RegTextField(controller: disease, label: '기저 질환 (선택사항)'),
          RegTextField(
            controller: deviceMac,
            label: '기기 MAC 주소 (AA:BB:CC:DD:EE:FF)',
            required: true,
            inputFormatters: [MacFormatter()],
            pattern: r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$',
            patternMsg: 'MAC 주소 형식이 올바르지 않습니다.',
          ),
        ],
      ),
    );
  }
}
