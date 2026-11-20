import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/route_model.dart';
import '../../providers/route_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/route_clock_time.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/osm_map_view.dart';

class AddEditRouteScreen extends StatefulWidget {
  final RouteModel? route;
  const AddEditRouteScreen({super.key, this.route});

  @override
  State<AddEditRouteScreen> createState() => _AddEditRouteScreenState();
}

class _StopEditors {
  final TextEditingController name;
  final TextEditingController lat;
  final TextEditingController lng;

  _StopEditors({String name = '', String lat = '', String lng = ''})
      : name = TextEditingController(text: name),
        lat = TextEditingController(text: lat),
        lng = TextEditingController(text: lng);

  void dispose() {
    name.dispose();
    lat.dispose();
    lng.dispose();
  }
}

class _AddEditRouteScreenState extends State<AddEditRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _distController;
  late TextEditingController _durController;
  late TextEditingController _depController;
  late TextEditingController _arrController;

  final List<_StopEditors> _stops = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.route?.routeName ?? '');
    _numberController =
        TextEditingController(text: widget.route?.routeNumber ?? '');
    _startController =
        TextEditingController(text: widget.route?.startLocation ?? '');
    _endController =
        TextEditingController(text: widget.route?.endLocation ?? '');
    _distController =
        TextEditingController(text: widget.route?.distanceKm ?? '');
    _durController =
        TextEditingController(text: widget.route?.estimatedTime ?? '');
    _depController =
        TextEditingController(text: widget.route?.departureTime ?? '');
    _arrController =
        TextEditingController(text: widget.route?.arrivalTime ?? '');

    if (widget.route != null) {
      final existingStops = [...widget.route!.stops]
        ..sort((a, b) => a.order.compareTo(b.order));
      if (existingStops.isNotEmpty) {
        for (final s in existingStops) {
          _stops.add(
            _StopEditors(
              name: s.stopName,
              lat: s.lat == 0 ? '' : s.lat.toString(),
              lng: s.lng == 0 ? '' : s.lng.toString(),
            ),
          );
        }
      } else {
        for (final name in widget.route!.viaStops) {
          _stops.add(_StopEditors(name: name));
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _startController.dispose();
    _endController.dispose();
    _distController.dispose();
    _durController.dispose();
    _depController.dispose();
    _arrController.dispose();
    for (final s in _stops) {
      s.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    setState(() => _stops.add(_StopEditors()));
  }

  Future<void> _pickClockTime({
    required TextEditingController controller,
    required TimeOfDay fallback,
  }) async {
    final initial = RouteClockTime.parse(controller.text) ?? fallback;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        final theme = Theme.of(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: AppColors.primary,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      controller.text = RouteClockTime.format(picked);
    });
    _formKey.currentState?.validate();
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _stops.add(
        _StopEditors(
          name: 'Stop ${_stops.length + 1}',
          lat: point.latitude.toStringAsFixed(6),
          lng: point.longitude.toStringAsFixed(6),
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added stop at ${point.latitude.toStringAsFixed(5)}, '
          '${point.longitude.toStringAsFixed(5)} — rename it below',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<({LatLng point, String label})> get _previewStops {
    final out = <({LatLng point, String label})>[];
    for (var i = 0; i < _stops.length; i++) {
      final s = _stops[i];
      final lat = double.tryParse(s.lat.text.trim());
      final lng = double.tryParse(s.lng.text.trim());
      if (lat == null || lng == null) continue;
      out.add((
        point: LatLng(lat, lng),
        label: s.name.text.trim().isEmpty ? 'Stop ${i + 1}' : s.name.text.trim(),
      ));
    }
    return out;
  }

  List<RouteStop> _buildStops() {
    final stops = <RouteStop>[];
    for (var i = 0; i < _stops.length; i++) {
      final s = _stops[i];
      final name = s.name.text.trim();
      if (name.isEmpty) continue;
      stops.add(
        RouteStop(
          stopName: name,
          lat: double.tryParse(s.lat.text.trim()) ?? 0.0,
          lng: double.tryParse(s.lng.text.trim()) ?? 0.0,
          order: i + 1,
        ),
      );
    }
    return stops;
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;

    final builtStops = _buildStops();
    final missingCoords = builtStops.any((s) => s.lat == 0 || s.lng == 0);
    if (builtStops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least 2 route points with coordinates for the map polyline',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (missingCoords) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Every route point needs latitude and longitude'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final routeId =
        widget.route?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final existing = widget.route;
    final viaStops = builtStops.map((e) => e.stopName).toList();
    final formFields = <String, dynamic>{
      'universityId': existing?.universityId.isNotEmpty == true
          ? existing!.universityId
          : 'uog',
      'routeName': _nameController.text.trim(),
      'routeNumber': _numberController.text.trim(),
      'startLocation': _startController.text.trim(),
      'endLocation': _endController.text.trim(),
      'distanceKm': _distController.text.trim(),
      'estimatedTime': _durController.text.trim(),
      'departureTime': _depController.text.trim(),
      'arrivalTime': _arrController.text.trim(),
      'viaStops': viaStops,
      'stops': builtStops.map((e) => e.toMap()).toList(),
    };
    // New only: default active. Edit: do not touch isActive / assignments.
    if (existing == null) {
      formFields['isActive'] = true;
    }

    try {
      await context.read<RouteProvider>().saveRouteFields(routeId, formFields);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Route ${widget.route == null ? 'added' : 'updated'} successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route == null ? 'Add Route' : 'Edit Route'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _numberController,
                labelText: 'Route Number (e.g., A)',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              CustomTextField(
                controller: _nameController,
                labelText: 'Route Name',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _startController,
                      labelText: 'Start Location',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _endController,
                      labelText: 'End Location',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _distController,
                      labelText: 'Distance (km)',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _durController,
                      labelText: 'Duration (e.g. 45 min)',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _depController,
                      labelText: 'Departure (e.g. 07:30 AM)',
                      readOnly: true,
                      suffixIcon: const Icon(Icons.access_time),
                      onTap: () => _pickClockTime(
                        controller: _depController,
                        fallback: const TimeOfDay(hour: 7, minute: 30),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _arrController,
                      labelText: 'Arrival (e.g. 08:15 AM)',
                      readOnly: true,
                      suffixIcon: const Icon(Icons.access_time),
                      onTap: () => _pickClockTime(
                        controller: _arrController,
                        fallback: const TimeOfDay(hour: 8, minute: 15),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (RouteClockTime.arrivalBeforeDeparture(
                          _depController.text,
                          v,
                        )) {
                          return 'Arrival must be after departure';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 40),
              const Text(
                'Route Points (Map Polyline)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap the map to place stops (no paid geocoding). '
                'Reorder by editing the list. Points become the live-tracking polyline.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: OsmMapView(
                    routePoints:
                        _previewStops.map((e) => e.point).toList(growable: false),
                    stops: [
                      for (var i = 0; i < _previewStops.length; i++)
                        OsmStopMarker(
                          point: _previewStops[i].point,
                          label: _previewStops[i].label,
                          isTerminal:
                              i == 0 || i == _previewStops.length - 1,
                        ),
                    ],
                    onTap: _onMapTap,
                    followBus: false,
                    initialZoom: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(_stops.length, (index) {
                final stop = _stops[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: stop.name,
                                validator: (v) =>
                                    v!.isEmpty ? 'Stop name required' : null,
                                decoration: InputDecoration(
                                  hintText: 'Stop name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () => setState(() {
                                stop.dispose();
                                _stops.removeAt(index);
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: stop.lat,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Lat required';
                                  }
                                  if (double.tryParse(v.trim()) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Latitude',
                                  hintText: '25.1450',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: stop.lng,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Lng required';
                                  }
                                  if (double.tryParse(v.trim()) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Longitude',
                                  hintText: '62.3600',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addStop,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('ADD ROUTE POINT'),
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: widget.route == null ? 'SAVE ROUTE' : 'UPDATE ROUTE',
                isLoading: _isLoading,
                onPressed: _saveRoute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
