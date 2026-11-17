import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/gps_location_model.dart';
import '../../models/route_model.dart';
import '../../models/trip_model.dart';
import '../../services/trip_tracking_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/map_marker_helper.dart';
import '../../widgets/osm_map_view.dart';

/// Admin: list ACTIVE trips and view live OSM map + route.
class AdminLiveTrackingScreen extends StatefulWidget {
  const AdminLiveTrackingScreen({super.key});

  @override
  State<AdminLiveTrackingScreen> createState() =>
      _AdminLiveTrackingScreenState();
}

class _AdminLiveTrackingScreenState extends State<AdminLiveTrackingScreen> {
  final _tripService = TripTrackingService();
  TripModel? _selected;
  RouteModel? _route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: StreamBuilder<List<TripModel>>(
              stream: _tripService.watchActiveTrips(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final trips = snap.data!;
                if (trips.isEmpty) {
                  return const Center(
                    child: Text('No active trips right now.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: trips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = trips[i];
                    final selected = _selected?.id == t.id;
                    final updated = t.updatedAt ?? t.startTime;
                    return Material(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 1,
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: const Icon(Icons.directions_bus,
                            color: AppColors.primary),
                        title: Text(
                          'Bus ${t.busNumber.isEmpty ? t.busId : t.busNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${t.routeName.isEmpty ? t.routeId : t.routeName}\n'
                          'Driver: ${t.driverName.isEmpty ? t.driverId : t.driverName}\n'
                          'Status: ${t.status}'
                          '${updated == null ? '' : ' · ${DateFormat('hh:mm a').format(updated.toLocal())}'}',
                        ),
                        isThreeLine: true,
                        onTap: () => _selectTrip(t),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 3,
            child: _selected == null
                ? const Center(
                    child: Text('Select an active bus to view the map'),
                  )
                : StreamBuilder<GpsLocationModel?>(
                    stream: _tripService.watchTripGps(_selected!.id),
                    builder: (context, gpsSnap) {
                      final gps = gpsSnap.data;
                      LatLng? bus;
                      if (gps != null && gps.hasValidCoords) {
                        bus = LatLng(gps.latitude, gps.longitude);
                      } else if (_selected?.lastLat != null &&
                          _selected?.lastLng != null) {
                        bus = LatLng(_selected!.lastLat!, _selected!.lastLng!);
                      }
                      return OsmMapView(
                        busLocation: bus,
                        routePoints: MapMarkerHelper.routePolyline(_route),
                        stops: MapMarkerHelper.stopMarkers(_route),
                        busLabel: _selected!.busNumber.isEmpty
                            ? 'BUS'
                            : _selected!.busNumber,
                        followBus: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTrip(TripModel trip) async {
    setState(() {
      _selected = trip;
      _route = null;
    });
    if (trip.routeId.isEmpty || Firebase.apps.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(trip.routeId)
          .get();
      if (doc.exists && doc.data() != null && mounted) {
        setState(() => _route = RouteModel.fromMap(doc.id, doc.data()!));
      }
    } catch (e) {
      debugPrint('Admin live load route failed: $e');
    }
  }
}
