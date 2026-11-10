import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notice_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notice_provider.dart';
import '../../utils/karachi_time.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class PostNoticeScreen extends StatefulWidget {
  final NoticeModel? notice;
  const PostNoticeScreen({super.key, this.notice});

  @override
  State<PostNoticeScreen> createState() => _PostNoticeScreenState();
}

class _PostNoticeScreenState extends State<PostNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _bodyController;

  late String _priority;
  late String _audience;
  DateTime? _expiresAt;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final n = widget.notice;
    _titleController = TextEditingController(text: n?.title ?? '');
    _bodyController = TextEditingController(text: n?.message ?? '');
    _priority = n?.priority ?? 'normal';
    _audience = n?.audience ?? 'all';
    _expiresAt = n?.expiresAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final day = await showDatePicker(
      context: context,
      initialDate: (_expiresAt ?? KarachiTime.now()).toLocal(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        (_expiresAt ?? DateTime.now().add(const Duration(hours: 2))).toLocal(),
      ),
    );
    if (time == null) return;
    setState(() {
      _expiresAt = KarachiTime.combineToUtc(day, time.hour, time.minute);
    });
  }

  Future<void> _saveNotice() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final notice = NoticeModel(
      id: widget.notice?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      message: _bodyController.text.trim(),
      audience: _audience,
      priority: _priority,
      isActive: widget.notice?.isActive ?? true,
      createdBy: widget.notice?.createdBy ?? (auth.uid ?? 'Admin'),
      createdAt: widget.notice?.createdAt ?? DateTime.now().toUtc(),
      expiresAt: _expiresAt,
      targetDriverId: widget.notice?.targetDriverId,
    );

    try {
      await context.read<NoticeProvider>().addNotice(notice);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.notice == null
                ? 'Notice posted successfully'
                : 'Notice updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.notice == null ? 'Post Notice' : 'Edit Notice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Priority',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _priorityBadge('Normal', Colors.blue, 'normal'),
                  const SizedBox(width: 8),
                  _priorityBadge('Important', Colors.orange, 'important'),
                  const SizedBox(width: 8),
                  _priorityBadge('Urgent', Colors.red, 'urgent'),
                ],
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _titleController,
                labelText: 'Notice Heading / Title',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              CustomTextField(
                controller: _bodyController,
                labelText: 'Message',
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _audience,
                decoration: InputDecoration(
                  labelText: 'Audience',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('Both (Drivers & Students)'),
                  ),
                  DropdownMenuItem(
                    value: 'drivers',
                    child: Text('Drivers only'),
                  ),
                  DropdownMenuItem(
                    value: 'students',
                    child: Text('Students only'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _audience = v);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expiry (optional)'),
                subtitle: Text(
                  _expiresAt == null
                      ? 'No expiry'
                      : KarachiTime.formatDateTime(_expiresAt!),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_expiresAt != null)
                      IconButton(
                        tooltip: 'Clear',
                        onPressed: () => setState(() => _expiresAt = null),
                        icon: const Icon(Icons.clear),
                      ),
                    IconButton(
                      tooltip: 'Pick expiry',
                      onPressed: _pickExpiry,
                      icon: const Icon(Icons.event),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: widget.notice == null ? 'BROADCAST NOTICE' : 'UPDATE NOTICE',
                isLoading: _isLoading,
                onPressed: _saveNotice,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityBadge(String label, Color color, String value) {
    final selected = _priority == value;
    return InkWell(
      onTap: () => setState(() => _priority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
