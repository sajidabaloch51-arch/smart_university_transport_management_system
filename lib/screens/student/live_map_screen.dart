import 'package:flutter/material.dart';
import 'live_bus_tracking_screen.dart';

/// Legacy alias — routes now use [LiveBusTrackingScreen].
class LiveMapScreen extends StatelessWidget {
  const LiveMapScreen({super.key});

  @override
  Widget build(BuildContext context) => const LiveBusTrackingScreen();
}
