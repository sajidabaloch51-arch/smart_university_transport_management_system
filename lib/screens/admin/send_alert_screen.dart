import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alert_model.dart';
import '../../models/driver_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../services/alert_service.dart';
import '../../utils/karachi_time.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class SendAlertScreen extends StatefulWidget {
  final AlertModel? alert;
  const SendAlertScreen({super.key, this.alert});

  @override
  State<SendAlertScreen> createState() => _SendAlertScreenState();
}

class _SendAlertScreenState extends State<SendAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _alertService = AlertService();

  String _severity = 'info';
  String _target = 'all_drivers';
  String? _driverId;
  DateTime? _expiresAt;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final a = widget.alert;
    if (a != null) {
      _titleController.text = a.title;
      _messageController.text = a.message;
      _severity = a.severity;
      _target = a.target;
      _driverId = a.driverId;
      _expiresAt = a.expiresAt;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_target == 'specific_driver' && (_driverId == null || _driverId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a driver for this alert')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final alert = AlertModel(
      id: widget.alert?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      severity: _severity,
      target: _target,
      driverId: _target == 'specific_driver' ? _driverId : null,
      isActive: widget.alert?.isActive ?? true,
      createdBy: widget.alert?.createdBy ?? (auth.uid ?? 'admin'),
      createdAt: widget.alert?.createdAt ?? DateTime.now().toUtc(),
      expiresAt: _expiresAt,
    );

    setState(() => _isLoading = true);
    try {
      await _alertService.saveAlert(alert);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.alert == null
              ? 'Alert sent successfully'
              : 'Alert updated successfully'),
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
        title: Text(widget.alert == null ? 'Send Alert' : 'Edit Alert'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _titleController,
                labelText: 'Title',
                prefixIcon: Icons.title,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              CustomTextField(
                controller: _messageController,
                labelText: 'Message',
                prefixIcon: Icons.message_outlined,
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _severity,
                decoration: InputDecoration(
                  labelText: 'Severity',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'info', child: Text('Info')),
                  DropdownMenuItem(value: 'warning', child: Text('Warning')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical')),
                ],
                onChanged: (v) => setState(() => _severity = v ?? 'info'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _target,
                decoration: InputDecoration(
                  labelText: 'Target',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'all_drivers', child: Text('All drivers')),
                  DropdownMenuItem(
                      value: 'specific_driver',
                      child: Text('Specific driver')),
                ],
                onChanged: (v) =>
                    setState(() => _target = v ?? 'all_drivers'),
              ),
              if (_target == 'specific_driver') ...[
                const SizedBox(height: 16),
                StreamBuilder<List<DriverModel>>(
                  stream: context.read<DriverProvider>().streamDrivers(),
                  builder: (context, snapshot) {
                    final list = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      initialValue: _driverId,
                      decoration: InputDecoration(
                        labelText: 'Driver',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: list
                          .map((d) => DropdownMenuItem(
                                value: d.uid,
                                child: Text(d.name,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _driverId = v),
                      validator: (v) =>
                          _target == 'specific_driver' && v == null
                              ? 'Required'
                              : null,
                    );
                  },
                ),
              ],
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expires at (optional)'),
                subtitle: Text(
                  _expiresAt == null
                      ? 'No expiry'
                      : '${KarachiTime.formatTime(_expiresAt!)} (${KarachiTime.dateString(_expiresAt)})',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_expiresAt != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _expiresAt = null),
                      ),
                    const Icon(Icons.event),
                  ],
                ),
                onTap: _pickExpiry,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: widget.alert == null ? 'SEND ALERT' : 'UPDATE ALERT',
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
