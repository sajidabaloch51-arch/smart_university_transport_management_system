import 'package:flutter/material.dart';

import 'live_bus_tracking_screen.dart';

/// Legacy alias — live tracking now uses Firestore + OsmMapView.
class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) => const LiveBusTrackingScreen();
}
