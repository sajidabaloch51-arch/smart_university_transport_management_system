import 'package:flutter/material.dart';
import '../../models/notice_model.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class PostNoticeScreen extends StatefulWidget {
  final NoticeModel? notice;
  const PostNoticeScreen({super.key, this.notice});

  @override
  State<PostNoticeScreen> createState() => _PostNoticeScreenState();
}

class _PostNoticeScreenState extends State<PostNoticeScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  
  late String _selectedType;
  late String _targetAudience;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.notice?.title ?? '');
    _bodyController = TextEditingController(text: widget.notice?.description ?? '');
    _selectedType = widget.notice?.type.name ?? 'general';
    _targetAudience = 'all'; // Default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.notice == null ? 'Post News / Notice' : 'Edit Notice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notice Classification', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _typeBadge('General', Colors.blue, 'general'),
                const SizedBox(width: 8),
                _typeBadge('Delay', Colors.orange, 'delay'),
                const SizedBox(width: 8),
                _typeBadge('Emergency', Colors.red, 'emergency'),
              ],
            ),
            const SizedBox(height: 30),
            CustomTextField(controller: _titleController, labelText: 'Notice Heading / Title'),
            CustomTextField(controller: _bodyController, labelText: 'Detailed Description', keyboardType: TextInputType.multiline),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _targetAudience,
              decoration: InputDecoration(labelText: 'Target Audience', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Users')),
                const DropdownMenuItem(value: 'students', child: Text('Students Only')),
                const DropdownMenuItem(value: 'drivers', child: Text('Drivers Only')),
              ],
              onChanged: (v) => setState(() => _targetAudience = v!),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: widget.notice == null ? 'BROADCAST NOTICE' : 'UPDATE NOTICE', 
              onPressed: () => Navigator.pop(context)
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(String label, Color color, String value) {
    final isSelected = _selectedType == value;
    return InkWell(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}
