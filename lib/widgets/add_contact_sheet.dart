import 'package:flutter/material.dart';
import '../models/ward_contact.dart';
import '../services/ward_service.dart';
import '../utils/input_formatters.dart';
import '../utils/phone_format.dart';

/// 연락처 추가/수정 폼 (바텀시트).
/// [existing]이 있으면 수정 모드(값 미리 채움), 없으면 추가 모드.
/// 성공 시 Navigator.pop(context, true) 반환 → 호출한 쪽이 목록 새로고침.
class AddContactSheet extends StatefulWidget {
  final WardContact? existing;
  const AddContactSheet({super.key, this.existing});

  @override
  State<AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<AddContactSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _relationship;
  static const _relationshipOptions = [
    '자녀', '부모', '배우자', '형제자매', '친척', '담당 복지사', '기타',
  ];
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // 수정 모드면 기존 값으로 채운다
    final c = widget.existing;
    if (c != null) {
      _name.text = c.name;
      _phone.text = formatPhone(c.phone); // 저장은 숫자 → 표시는 하이픈
      _relationship = c.relationship;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // 서버에는 숫자만 전송 (하이픈 제거)
      final phone = phoneDigits(_phone.text);
      if (_isEdit) {
        await WardService.updateContact(
          contactId: widget.existing!.contactId,
          name: _name.text.trim(),
          phone: phone,
          relationship: _relationship ?? '',
        );
      } else {
        await WardService.addContact(
          name: _name.text.trim(),
          phone: phone,
          relationship: _relationship ?? '',
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true); // 성공 → true 반환
    } catch (e) {
      debugPrint('연락처 저장 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 키보드가 올라와도 폼이 가려지지 않게 하단 여백 확보
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? '연락처 수정' : '연락처 추가',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '이름을 입력해주세요' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.number,
              inputFormatters: [DashFormatter([3, 4, 4])],
              decoration: const InputDecoration(
                labelText: '전화번호 (010-XXXX-XXXX)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return '전화번호를 입력해주세요';
                if (!RegExp(r'^010-\d{4}-\d{4}$').hasMatch(s)) {
                  return '전화번호 형식이 올바르지 않습니다.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _relationship,
              decoration: const InputDecoration(
                labelText: '관계',
                border: OutlineInputBorder(),
              ),
              items: _relationshipOptions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _relationship = v),
              validator: (v) => v == null ? '관계를 선택해주세요' : null,
            ),
            const SizedBox(height: 20),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _submit,
                    child: Text(_isEdit ? '수정하기' : '추가하기'),
                  ),
          ],
        ),
      ),
    );
  }
}
