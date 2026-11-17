import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../models/duty_model.dart';
import '../../services/duty_service.dart';
import '../../utils/map_marker_helper.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/duty_card.dart';
import '../../widgets/osm_map_view.dart';

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
    // Ordered list: Auth uid first (rules-safe), then profile uid, then seed id.
    final ids = <String>[];
    void addId(String? id) {
      if (id == null || id.isEmpty || ids.contains(id)) return;
      ids.add(id);
    }

    addId(context.read<AuthProvider>().uid);
    addId(context.read<DriverProvider>().driver?.uid);
    addId('driver_id'); // seed duties; readable once isDriver() mirror works
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
        final media = MediaQuery.of(context);
        final mapHeight =
            (media.size.height * 0.35).clamp(240.0, 420.0).toDouble();

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + media.viewPadding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusBadge(isOnDuty: isOnDuty),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 120),
                  child: _stream == null
                      ? const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : AsyncStateView<List<DutyModel>>(
                          stream: _stream!,
                          isEmpty: (duties) => duties.isEmpty,
                          emptyMessage: 'No duties assigned yet.',
                          emptySubtitle:
                              'When Admin assigns a duty, it will show up here. '
                              'You can still START TRIP if a bus and route are assigned.',
                          timeout: const Duration(seconds: 12),
                          onRetry: () {
                            setState(() {
                              _stream = null;
                              _boundUid = null;
                            });
                            _bind();
                          },
                          builder: (context, duties) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final d in duties) DutyCard(duty: d),
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.05,
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
                if (provider.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: CustomButton(
                    text: isOnDuty ? 'END TRIP' : 'START TRIP',
                    color: isOnDuty ? Colors.red : Colors.green,
                    isLoading: provider.isLoading,
                    icon: isOnDuty
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_fill_rounded,
                    onPressed: () async {
                      await provider.toggleDuty();
                      if (!context.mounted) return;
                      final err = provider.error;
                      if (err != null && err.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(err),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: mapHeight,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: OsmMapView(
                      busLocation: provider.currentPosition == null
                          ? null
                          : LatLng(
                              provider.currentPosition!.latitude,
                              provider.currentPosition!.longitude,
                            ),
                      routePoints: MapMarkerHelper.routePolyline(
                        provider.assignedRoute,
                      ),
                      stops: MapMarkerHelper.stopMarkers(
                        provider.assignedRoute,
                      ),
                      busLabel:
                          provider.driver?.assignedBusNumber.isNotEmpty == true
                              ? provider.driver!.assignedBusNumber
                              : 'BUS',
                      followBus: isOnDuty,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnDuty ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isOnDuty ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isOnDuty ? Icons.radar_rounded : Icons.offline_bolt_rounded,
            size: 40,
            color: isOnDuty ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOnDuty ? 'TRIP ACTIVE' : 'TRIP OFFLINE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color:
                        isOnDuty ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
                Text(
                  isOnDuty
                      ? 'Sharing GPS with students & admin'
                      : 'Start trip to share location',
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isOnDuty ? Colors.green.shade700 : Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.all(16),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
