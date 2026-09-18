import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/driver_provider.dart';
import '../../models/schedule_model.dart';
import '../../models/route_model.dart';
import '../../models/driver_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final ScheduleModel? schedule;
  const AddEditScheduleScreen({super.key, this.schedule});

  @override
  State<AddEditScheduleScreen> createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRouteId;
  String? _selectedDriverId;
  late TextEditingController _vehicleController;
  
  late DateTime _selectedDate;
  late TimeOfDay _departureTime;
  late TimeOfDay _arrivalTime;
  String _selectedShift = 'Morning';
  String _selectedStatus = 'Scheduled';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRouteId = widget.schedule?.routeId;
    _selectedDriverId = widget.schedule?.driverId;
    _vehicleController = TextEditingController(text: widget.schedule?.vehicleNo ?? '');
    
    _selectedDate = widget.schedule?.date ?? DateTime.now();
    _departureTime = const TimeOfDay(hour: 7, minute: 30); // Default or parse from schedule
    _arrivalTime = const TimeOfDay(hour: 8, minute: 0);
    _selectedShift = widget.schedule?.shift ?? 'Morning';
    _selectedStatus = widget.schedule?.status ?? 'Scheduled';
  }
  
  @override
  void dispose() {
    _vehicleController.dispose();
    super.dispose();
  }

  void _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRouteId == null || _selectedDriverId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select route and driver')));
        return;
      }
      
      setState(() => _isLoading = true);

      final routeProvider = Provider.of<RouteProvider>(context, listen: false);
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);

      String rName = 'Route Name';
      String dName = 'Driver Name';

      try {
        final routesList = await routeProvider.streamRoutes().first;
        final selectedRouteObj = routesList.firstWhere((r) => r.id == _selectedRouteId);
        rName = selectedRouteObj.routeName;
      } catch (_) {}

      try {
        final driversList = await driverProvider.streamDrivers().first;
        final selectedDriverObj = driversList.firstWhere((d) => d.uid == _selectedDriverId);
        dName = selectedDriverObj.name;
      } catch (_) {}
      
      final schedule = ScheduleModel(
        id: widget.schedule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        driverId: _selectedDriverId!,
        driverName: dName,
        routeId: _selectedRouteId!,
        routeName: rName,
        date: _selectedDate,
        departureTime: _departureTime.format(context),
        arrivalTime: _arrivalTime.format(context),
        shift: _selectedShift,
        vehicleNo: _vehicleController.text.trim(),
        status: _selectedStatus,
      );

      try {
        await Provider.of<ScheduleProvider>(context, listen: false).addSchedule(schedule);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Schedule ${widget.schedule == null ? 'added' : 'updated'} successfully'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context);
    final driverProvider = Provider.of<DriverProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.schedule == null ? 'Add Schedule' : 'Edit Schedule')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<List<RouteModel>>(
                stream: routeProvider.streamRoutes(),
                builder: (context, snapshot) {
                  final routes = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedRouteId,
                    decoration: InputDecoration(labelText: 'Select Route', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: routes.map((r) => DropdownMenuItem(value: r.id, child: Text(r.routeName))).toList(),
                    onChanged: (v) => setState(() => _selectedRouteId = v),
                  );
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<DriverModel>>(
                stream: driverProvider.streamDrivers(),
                builder: (context, snapshot) {
                  final drivers = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedDriverId,
                    decoration: InputDecoration(labelText: 'Select Driver', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: drivers.map((d) => DropdownMenuItem(value: d.uid, child: Text(d.name))).toList(),
                    onChanged: (v) => setState(() => _selectedDriverId = v),
                  );
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _vehicleController,
                labelText: 'Vehicle Number',
                prefixIcon: Icons.directions_bus,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              
              const Divider(height: 40),
              
              DropdownButtonFormField<String>(
                value: _selectedShift,
                decoration: InputDecoration(labelText: 'Shift', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: ['Morning', 'Evening', 'Night'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _selectedShift = v!),
              ),
              
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Operational Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
              ),
              Wrap(
                spacing: 8,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                  return ChoiceChip(
                    label: Text(day),
                    selected: true,
                    onSelected: (val) {},
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTimePicker('Departure', _departureTime, (t) => setState(() => _departureTime = t))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimePicker('Arrival', _arrivalTime, (t) => setState(() => _arrivalTime = t))),
                ],
              ),
              
              const SizedBox(height: 50),
              CustomButton(
                text: widget.schedule == null ? 'SAVE SCHEDULE' : 'UPDATE SCHEDULE', 
                isLoading: _isLoading,
                onPressed: _saveSchedule,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onPicked) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: time);
        if (t != null) onPicked(t);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(time.format(context), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
