import 'package:flutter/material.dart';
import '../../models/notice_model.dart';
import '../../services/firestore_service.dart';

class PostNoticeScreen extends StatefulWidget {
  const PostNoticeScreen({super.key});

  @override
  State<PostNoticeScreen> createState() => _PostNoticeScreenState();
}

class _PostNoticeScreenState extends State<PostNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _type = 'general';
  String _targetRole = 'all';

  void _postNotice() async {
    if (!_formKey.currentState!.validate()) return;

    final notice = NoticeModel(
      id: '',
      universityId: 'uog',
      title: _titleController.text,
      body: _bodyController.text,
      type: _type,
      targetRole: _targetRole,
      postedBy: 'admin_123',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 1)), // Default 1 day
    );

    await _firestoreService.addNotice(notice);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice posted successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post New Notice')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Notice Type'),
              items: ['general', 'delay', 'cancellation', 'emergency'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
              }).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Message Body', border: OutlineInputBorder()),
              maxLines: 5,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _targetRole,
              decoration: const InputDecoration(labelText: 'Target Audience'),
              items: ['all', 'student', 'driver'].map((role) {
                return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
              }).toList(),
              onChanged: (v) => setState(() => _targetRole = v!),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _postNotice,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('POST NOTICE'),
            ),
          ],
        ),
      ),
    );
  }
}
