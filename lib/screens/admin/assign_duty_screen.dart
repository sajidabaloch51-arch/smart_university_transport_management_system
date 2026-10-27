import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/duty_model.dart';
import '../../models/driver_model.dart';
import '../../models/bus_model.dart';
import '../../models/route_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/bus_provider.dart';
import '../../providers/route_provider.dart';
import '../../services/duty_service.dart';
import '../../services/route_assignment_service.dart';
import '../../utils/karachi_time.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AssignDutyScreen extends StatefulWidget {
  final DutyModel? duty;
  const AssignDutyScreen({super.key, this.duty});

  @override
  State<AssignDutyScreen> createState() => _AssignDutyScreenState();
}

class _AssignDutyScreenState extends State<AssignDutyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _dutyService = DutyService();
  final _routeAssignment = RouteAssignmentService();

  String? _driverId;
  String? _driverName;
  String? _driverPhone;
  String? _busNo;
  String? _routeId;
  String? _routeName;
  DateTime _dutyDay = KarachiTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _end = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.duty;
    if (d != null) {
      _driverId = d.driverId;
      _driverName = d.driverName;
      _busNo = d.busNo;
      _routeId = d.routeId.isNotEmpty ? d.routeId : null;
      _routeName = d.route;
      _notesController.text = d.notes;
      final parts = d.dutyDate.split('-');
      if (parts.length == 3) {
        _dutyDay = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      final startK = d.shiftStart.toUtc().add(KarachiTime.offset);
      final endK = d.shiftEnd.toUtc().add(KarachiTime.offset);
      _start = TimeOfDay(hour: startK.hour, minute: startK.minute);
      _end = TimeOfDay(hour: endK.hour, minute: endK.minute);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dutyDay,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _dutyDay = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_driverId == null || _busNo == null || _routeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select driver, bus, and route')),
      );
      return;
    }

    final startUtc =
        KarachiTime.combineToUtc(_dutyDay, _start.hour, _start.minute);
    final endUtc = KarachiTime.combineToUtc(_dutyDay, _end.hour, _end.minute);
    if (!endUtc.isAfter(startUtc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final duty = DutyModel(
      id: widget.duty?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      driverId: _driverId!,
      driverName: _driverName ?? '',
      busNo: _busNo!,
      routeId: _routeId!,
      route: _routeName ?? '',
      shiftStart: startUtc,
      shiftEnd: endUtc,
      dutyDate:
          '${_dutyDay.year.toString().padLeft(4, '0')}-'
          '${_dutyDay.month.toString().padLeft(2, '0')}-'
          '${_dutyDay.day.toString().padLeft(2, '0')}',
      notes: _notesController.text.trim(),
      status: widget.duty?.status ?? 'scheduled',
      createdBy: widget.duty?.createdBy ?? (auth.uid ?? 'admin'),
      createdAt: widget.duty?.createdAt ?? DateTime.now().toUtc(),
    );

    setState(() => _isLoading = true);
    try {
      final conflict = await _dutyService.findOverlapConflict(duty);
      if (conflict != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(conflict), backgroundColor: Colors.red),
        );
        return;
      }

      await _dutyService.saveDuty(duty);

      // Source of truth for student My Routes: routes/{routeId}.
      var phone = _driverPhone ?? '';
      if (phone.isEmpty) {
        try {
          final driverProvider = context.read<DriverProvider>();
          final snap = await driverProvider
              .streamDrivers()
              .first
              .timeout(const Duration(seconds: 5));
          final match = snap.where((d) => d.uid == _driverId).toList();
          if (match.isNotEmpty) phone = match.first.phone;
        } catch (_) {}
      }
      if (!mounted) return;
      await _routeAssignment.assignDriverToRoute(
        routeId: _routeId!,
        driverId: _driverId!,
        driverName: _driverName ?? '',
        driverPhone: phone,
        busNo: _busNo!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.duty == null
              ? 'Duty assigned successfully'
              : 'Duty updated successfully'),
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
    final drivers = context.watch<DriverProvider>();
    final buses = context.watch<BusProvider>();
    final routes = context.watch<RouteProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.duty == null ? 'Assign Duty' : 'Edit Duty'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StreamBuilder<List<DriverModel>>(
                stream: drivers.streamDrivers(),
                builder: (context, snapshot) {
                  final list = (snapshot.data ?? [])
                      .where((d) =>
                          d.status.toLowerCase() != 'inactive' &&
                          d.status.toLowerCase() != 'on leave')
                      .toList();
                  return DropdownButtonFormField<String>(
                    initialValue: _driverId,
                    decoration: InputDecoration(
                      labelText: 'Driver',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    // value = Firestore users/{uid} document id (same uid used at login)
                    items: list
                        .map((d) => DropdownMenuItem(
                              value: d.uid,
                              child: Text(
                                '${d.name} (${d.uid})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      final match =
                          list.where((d) => d.uid == v).toList();
                      setState(() {
                        _driverId = v; // Firestore users/{uid}
                        _driverName =
                            match.isEmpty ? null : match.first.name;
                        _driverPhone =
                            match.isEmpty ? null : match.first.phone;
                      });
                      debugPrint('AssignDuty selected driverId=$_driverId');
                    },
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<BusModel>>(
                stream: buses.streamBuses(),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  final numbers = list
                      .map((b) => b.busNumber)
                      .where((n) => n.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
                  if (_busNo != null && !numbers.contains(_busNo)) {
                    numbers.insert(0, _busNo!);
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: numbers.contains(_busNo) ? _busNo : null,
                    decoration: InputDecoration(
                      labelText: 'Bus Number',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: numbers
                        .map((n) =>
                            DropdownMenuItem(value: n, child: Text(n)))
                        .toList(),
                    onChanged: (v) => setState(() => _busNo = v),
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<RouteModel>>(
                stream: routes.streamRoutes(),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  // Value = stable routeId (never route name text).
                  final ids = list.map((r) => r.id).toList();
                  if (_routeId != null && !ids.contains(_routeId)) {
                    // Legacy duty may only have a name — try resolve once.
                    final byName = list
                        .where((r) => r.routeName == _routeName)
                        .toList();
                    if (byName.isNotEmpty) {
                      _routeId = byName.first.id;
                    }
                  }
                  return DropdownButtonFormField<String>(
                    initialValue:
                        ids.contains(_routeId) ? _routeId : null,
                    decoration: InputDecoration(
                      labelText: 'Route',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: list
                        .map((r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(
                                r.routeName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      final match =
                          list.where((r) => r.id == v).toList();
                      setState(() {
                        _routeId = v;
                        _routeName =
                            match.isEmpty ? null : match.first.routeName;
                      });
                    },
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Duty Date'),
                subtitle: Text(
                  '${_dutyDay.year.toString().padLeft(4, '0')}-'
                  '${_dutyDay.month.toString().padLeft(2, '0')}-'
                  '${_dutyDay.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start'),
                      subtitle: Text(_start.format(context)),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End'),
                      subtitle: Text(_end.format(context)),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              CustomTextField(
                controller: _notesController,
                labelText: 'Notes (optional)',
                prefixIcon: Icons.notes,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: widget.duty == null ? 'SAVE DUTY' : 'UPDATE DUTY',
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
