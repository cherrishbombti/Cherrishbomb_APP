import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ward_contact.dart';
import '../services/ward_service.dart';
import '../widgets/add_contact_sheet.dart';

/// 비상 연락망 화면. 연락처 목록 조회 + 추가.
/// (우선순위 드래그 변경은 백엔드 미지원이라 이번 범위에서 제외)
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  bool _loading = true;
  String? _error;
  List<WardContact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final contacts = await WardService.getContacts();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (e) {
      debugPrint('연락처 목록 로드 실패: $e');
      if (!mounted) return;
      setState(() {
        _error = '연락처를 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  // 추가 바텀시트를 열고, 추가되면 목록 새로고침
  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true, // 키보드에 맞춰 올라오게
      builder: (_) => const AddContactSheet(),
    );
    if (added == true) _load();
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화를 걸 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비상 연락망')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('연락처 추가'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_contacts.isEmpty) {
      return const Center(
        child: Text(
          '등록된 비상 연락처가 없습니다.\n아래 버튼으로 추가하세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contacts.length,
        itemBuilder: (_, i) => _contactCard(_contacts[i], i),
      ),
    );
  }

  Widget _contactCard(WardContact c, int index) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(c.name.isNotEmpty ? c.name[0] : '?'),
        ),
        title: Text('${c.name} (${c.relationship})'),
        subtitle: Text(c.phone),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '우선순위 ${index + 1}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              tooltip: '전화 걸기',
              onPressed: () => _callPhone(c.phone),
            ),
          ],
        ),
      ),
    );
  }
}
