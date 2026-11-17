import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

/// Shared OpenStreetMap view (flutter_map) — no Google Maps API.
class OsmMapView extends StatefulWidget {
  final LatLng? busLocation;
  final LatLng? userLocation;
  final List<LatLng> routePoints;
  final List<OsmStopMarker> stops;
  final String? busLabel;
  final bool followBus;
  final ValueChanged<LatLng>? onTap;
  final double initialZoom;

  const OsmMapView({
    super.key,
    this.busLocation,
    this.userLocation,
    this.routePoints = const [],
    this.stops = const [],
    this.busLabel,
    this.followBus = true,
    this.onTap,
    this.initialZoom = 14,
  });

  /// University of Gwadar — camera fallback only (never fake bus GPS).
  static const LatLng gwadarFallback = LatLng(25.1450, 62.3600);

  @override
  State<OsmMapView> createState() => _OsmMapViewState();
}

class OsmStopMarker {
  final LatLng point;
  final String label;
  final bool isTerminal;

  const OsmStopMarker({
    required this.point,
    required this.label,
    this.isTerminal = false,
  });
}

class _OsmMapViewState extends State<OsmMapView> {
  MapController _controller = MapController();
  Key _mapKey = UniqueKey();
  bool _tilesError = false;
  bool _fitted = false;
  bool _mapReady = false;

  LatLng get _center {
    if (widget.busLocation != null && _isValidLatLng(widget.busLocation!)) {
      return widget.busLocation!;
    }
    if (widget.userLocation != null && _isValidLatLng(widget.userLocation!)) {
      return widget.userLocation!;
    }
    for (final p in widget.routePoints) {
      if (_isValidLatLng(p)) return p;
    }
    for (final s in widget.stops) {
      if (_isValidLatLng(s.point)) return s.point;
    }
    return OsmMapView.gwadarFallback;
  }

  static bool _isValidLatLng(LatLng p) =>
      p.latitude.isFinite &&
      p.longitude.isFinite &&
      p.latitude.abs() <= 90 &&
      p.longitude.abs() <= 180;

  double get _safeZoom {
    if (!_mapReady) return widget.initialZoom;
    try {
      final z = _controller.camera.zoom;
      if (z.isFinite && z >= 1 && z <= 22) return z;
    } catch (_) {}
    return widget.initialZoom;
  }

  void _resetController() {
    try {
      _controller.dispose();
    } catch (_) {}
    _controller = MapController();
    _mapKey = UniqueKey();
    _fitted = false;
    _mapReady = false;
  }

  void _safeMove(LatLng target, [double? zoom]) {
    if (!_mapReady) return;
    if (!_isValidLatLng(target)) return;
    final z = (zoom ?? _safeZoom).clamp(1.0, 19.0);
    if (!z.isFinite) return;
    try {
      _controller.move(target, z);
    } catch (_) {
      _resetController();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    try {
      _controller.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OsmMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.followBus &&
        widget.busLocation != null &&
        oldWidget.busLocation != widget.busLocation &&
        _isValidLatLng(widget.busLocation!)) {
      _safeMove(widget.busLocation!);
    }
    if (!_fitted &&
        (widget.routePoints.length >= 2 || widget.busLocation != null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  void _fitBounds() {
    if (!mounted || !_mapReady) return;
    final pts = <LatLng>[
      ...widget.routePoints.where(_isValidLatLng),
      if (widget.busLocation != null && _isValidLatLng(widget.busLocation!))
        widget.busLocation!,
      if (widget.userLocation != null && _isValidLatLng(widget.userLocation!))
        widget.userLocation!,
      ...widget.stops.map((s) => s.point).where(_isValidLatLng),
    ];
    if (pts.length < 2) {
      _safeMove(_center, widget.initialZoom);
      _fitted = true;
      return;
    }
    var minLat = pts.first.latitude;
    var maxLat = pts.first.latitude;
    var minLng = pts.first.longitude;
    var maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    // Degenerate / near-zero bounds → NaN zoom inside flutter_map.
    if ((maxLat - minLat).abs() < 1e-6 && (maxLng - minLng).abs() < 1e-6) {
      _safeMove(pts.first, widget.initialZoom);
      _fitted = true;
      return;
    }
    try {
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
          padding: const EdgeInsets.all(48),
        ),
      );
      if (!_safeZoom.isFinite) {
        _safeMove(_center, widget.initialZoom);
      }
      _fitted = true;
    } catch (_) {
      _safeMove(_center, widget.initialZoom);
      _fitted = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (!w.isFinite || !h.isFinite || w < 32 || h < 32) {
          return const ColoredBox(
            color: Color(0xFFE8EEF5),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              key: _mapKey,
              mapController: _controller,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: widget.initialZoom.clamp(1.0, 19.0),
                backgroundColor: const Color(0xFFE8EEF5),
                onMapReady: () {
                  _mapReady = true;
                  if (!_fitted &&
                      (widget.routePoints.length >= 2 ||
                          widget.busLocation != null)) {
                    _fitBounds();
                  }
                },
                onTap: widget.onTap == null
                    ? null
                    : (tap, latLng) => widget.onTap!(latLng),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.sutms',
                  maxZoom: 19,
                  errorTileCallback: (tile, error, stack) {
                    if (!_tilesError && mounted) {
                      setState(() => _tilesError = true);
                    }
                  },
                ),
                if (widget.routePoints.where(_isValidLatLng).length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points:
                            widget.routePoints.where(_isValidLatLng).toList(),
                        color: const Color(0xFF1565C0),
                        strokeWidth: 4.5,
                      ),
                    ],
                  ),
                MarkerLayer(markers: [
                  ...widget.stops.where((s) => _isValidLatLng(s.point)).map((s) {
                    return Marker(
                      point: s.point,
                      width: 36,
                      height: 36,
                      child: Tooltip(
                        message: s.label,
                        child: Icon(
                          s.isTerminal ? Icons.flag : Icons.location_on,
                          color: s.isTerminal
                              ? const Color(0xFF00897B)
                              : AppColors.primary,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                  if (widget.userLocation != null &&
                      _isValidLatLng(widget.userLocation!))
                    Marker(
                      point: widget.userLocation!,
                      width: 28,
                      height: 28,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Color(0xFF00897B),
                        size: 30,
                      ),
                    ),
                  if (widget.busLocation != null &&
                      _isValidLatLng(widget.busLocation!))
                    Marker(
                      point: widget.busLocation!,
                      width: 56,
                      height: 56,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.busLabel ?? 'BUS',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.directions_bus,
                              color: Color(0xFF0D47A1),
                              size: 26,
                            ),
                          ],
                        ),
                      ),
                    ),
                ]),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
            if (_tilesError)
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: Material(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'Map tiles could not load. Check internet connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                children: [
                  _MapFab(
                    icon: Icons.add,
                    onTap: () => _safeMove(
                      _center,
                      _safeZoom + 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MapFab(
                    icon: Icons.remove,
                    onTap: () => _safeMove(
                      _center,
                      _safeZoom - 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MapFab(
                    icon: Icons.my_location,
                    onTap: () {
                      final target = widget.userLocation ??
                          widget.busLocation ??
                          _center;
                      _safeMove(target, 16);
                    },
                  ),
                  const SizedBox(height: 8),
                  _MapFab(
                    icon: Icons.fit_screen,
                    onTap: () {
                      _fitted = false;
                      _fitBounds();
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: AppColors.primary),
        ),
      ),
    );
  }
}
