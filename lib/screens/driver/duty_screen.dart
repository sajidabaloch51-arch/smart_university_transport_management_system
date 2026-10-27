import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../models/duty_model.dart';
import '../../services/duty_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/duty_card.dart';

class DutyScreen extends StatefulWidget {
  final int refreshToken;
  const DutyScreen({super.key, this.refreshToken = 0});

  @override
  State<DutyScreen> createState() => _DutyScreenState();
}

class _DutyScreenState extends State<DutyScreen> {
  final _dutyService = DutyService();
  Stream<List<DutyModel>>? _stream;
  String? _boundUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bind();
  }

  @override
  void didUpdateWidget(covariant DutyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _stream = null;
      _boundUid = null;
      _bind();
    }
  }

  void _bind() {
    final ids = <String>{};
    final dUid = context.read<DriverProvider>().driver?.uid;
    final aUid = context.read<AuthProvider>().uid;
    if (dUid != null && dUid.isNotEmpty) ids.add(dUid);
    if (aUid != null && aUid.isNotEmpty) ids.add(aUid);
    ids.add('driver_id');
    if (ids.isEmpty) {
      debugPrint('DutyScreen waiting for uid…');
      return;
    }
    final key = ids.join('|');
    if (_stream != null && _boundUid == key) return;
    _boundUid = key;
    final primary = ids.first;
    debugPrint('DutyScreen binding stream ids=$ids');
    _stream = _dutyService.streamDriverDuties(
      primary,
      alternateDriverIds: ids.skip(1).toList(),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, provider, child) {
        if (_stream == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _bind();
          });
        }

        final driver = provider.driver;
        if (driver == null) {
          return const Center(child: Text('Error loading status'));
        }

        final isOnDuty = driver.isOnDuty;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _StatusBadge(isOnDuty: isOnDuty),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Assigned Duties',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: StreamBuilder<List<DutyModel>>(
                  stream: _stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      final err = snapshot.error;
                      if (err is FirebaseException) {
                        debugPrint(
                          '🔥 DutyScreen error code=${err.code} message=${err.message}',
                        );
                      }
                      return Text(
                        'Could not load duties.',
                        style: TextStyle(color: Colors.red.shade700),
                      );
                    }
                    if (_stream == null ||
                        (snapshot.connectionState == ConnectionState.waiting &&
                            !snapshot.hasData)) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final duties = snapshot.data ?? [];
                    if (duties.isEmpty) {
                      return Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: const Text(
                          'No duties assigned yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return ListView(
                      children: duties.map((d) => DutyCard(duty: d)).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    _StatTile(
                      icon: Icons.timer,
                      value: _formatDuration(provider.dutyDuration),
                      label: 'Duty Timer',
                    ),
                    _StatTile(
                      icon: Icons.speed_rounded,
                      value:
                          '${provider.currentPosition?.speed.toStringAsFixed(1) ?? "0.0"} km/h',
                      label: 'Current Speed',
                    ),
                    _StatTile(
                      icon: Icons.my_location,
                      value:
                          '${provider.currentPosition?.latitude.toStringAsFixed(4) ?? "0.0"}, ${provider.currentPosition?.longitude.toStringAsFixed(4) ?? "0.0"}',
                      label: 'GPS Coordinates',
                    ),
                    _StatTile(
                      icon: Icons.bus_alert,
                      value: provider.assignedRoute?.viaStops.isNotEmpty == true
                          ? provider.assignedRoute!.viaStops.first
                          : 'N/A',
                      label: 'Next Stop',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: isOnDuty ? 'END DUTY' : 'START DUTY',
                color: isOnDuty ? Colors.red : Colors.green,
                isLoading: provider.isLoading,
                icon: isOnDuty
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_fill_rounded,
                onPressed: () => provider.toggleDuty(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOnDuty;
  const _StatusBadge({required this.isOnDuty});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: isOnDuty ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isOnDuty ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOnDuty ? Icons.radar_rounded : Icons.offline_bolt_rounded,
            size: 50,
            color: isOnDuty ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOnDuty ? 'TRACKING ACTIVE' : 'TRACKING OFFLINE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isOnDuty ? Colors.green.shade900 : Colors.red.shade900,
                ),
              ),
              Text(
                isOnDuty
                    ? 'Broadcasting live location'
                    : 'Duty session not started',
                style: TextStyle(
                  color: isOnDuty ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
