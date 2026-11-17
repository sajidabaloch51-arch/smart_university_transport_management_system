import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_model.dart';
import '../widgets/osm_map_view.dart';

/// Helpers for OSM map markers / polylines (no Google Maps).
class MapMarkerHelper {
  MapMarkerHelper._();

  static List<LatLng> routePolyline(RouteModel? route) {
    if (route == null) return const [];
    final stops = [...route.stops]
      ..sort((a, b) => a.order.compareTo(b.order));
    final pts = <LatLng>[];
    for (final s in stops) {
      if (s.lat.abs() > 0.0001 || s.lng.abs() > 0.0001) {
        pts.add(LatLng(s.lat, s.lng));
      }
    }
    return pts;
  }

  static List<OsmStopMarker> stopMarkers(RouteModel? route) {
    if (route == null) return const [];
    final stops = [...route.stops]
      ..sort((a, b) => a.order.compareTo(b.order));
    final out = <OsmStopMarker>[];
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      if (s.lat.abs() < 0.0001 && s.lng.abs() < 0.0001) continue;
      out.add(
        OsmStopMarker(
          point: LatLng(s.lat, s.lng),
          label: s.stopName.isEmpty ? 'Stop ${i + 1}' : s.stopName,
          isTerminal: i == 0 || i == stops.length - 1,
        ),
      );
    }
    return out;
  }

  static Widget busIcon({Color color = const Color(0xFF0D47A1)}) {
    return Icon(Icons.directions_bus, color: color, size: 32);
  }
}
