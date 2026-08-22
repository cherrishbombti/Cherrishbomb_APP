import 'package:flutter/material.dart';
import '../utils/input_formatters.dart';
import 'reg_text_field.dart';

/// STEP1 — 보호자 정보 (이름·연락처·관계).
/// 관계는 드롭다운, '기타' 선택 시 직접 입력 필드가 나타난다.
class RegStep1 extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController relationship; // 최종 관계 값
  const RegStep1({
    super.key,
    required this.formKey,
    required this.name,
    required this.phone,
    required this.relationship,
  });

  @override
  State<RegStep1> createState() => _RegStep1State();
}

class _RegStep1State extends State<RegStep1> {
  String? _selected;
  static const _options = ['자녀', '부모', '배우자', '형제자매', '친척', '기타'];

  void _onSelect(String? v) {
    setState(() => _selected = v);
    // '기타'는 사용자가 직접 입력 → 값 비움. 그 외엔 선택값을 그대로 저장.
    if (v != null && v != '기타') {
      widget.relationship.text = v;
    } else {
      widget.relationship.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegTextField(controller: widget.name, label: '이름', required: true),
          RegTextField(
            controller: widget.phone,
            label: '연락처 (010-XXXX-XXXX)',
            required: true,
            inputFormatters: [
              DashFormatter([3, 4, 4]),
            ],
            pattern: r'^010-\d{4}-\d{4}$',
            patternMsg: '전화번호 형식이 올바르지 않습니다.',
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DropdownButtonFormField<String>(
              initialValue: _selected,
              decoration: const InputDecoration(labelText: '피보호자와의 관계', border: OutlineInputBorder()),
              items: _options.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: _onSelect,
              validator: (v) => v == null ? '관계를 선택해주세요' : null,
            ),
          ),
          if (_selected == '기타') RegTextField(controller: widget.relationship, label: '관계 직접 입력', required: true),
        ],
      ),
    );
  }
}

/// STEP2 — 피보호자 정보 (이름·주소·연락처·MAC·기저질환).
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
            inputFormatters: [
              DashFormatter([3, 4, 4]),
            ],
            pattern: r'^010-\d{4}-\d{4}$',
            patternMsg: '전화번호 형식이 올바르지 않습니다.',
          ),
          RegTextField(
            controller: deviceMac,
            label: '기기 MAC 주소 (AA:BB:CC:DD:EE:FF)',
            required: true,
            inputFormatters: [MacFormatter()],
            pattern: r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$',
            patternMsg: 'MAC 주소 형식이 올바르지 않습니다.',
          ),
          RegTextField(controller: disease, label: '기저 질환 (선택사항)'),
        ],
      ),
    );
  }
}
