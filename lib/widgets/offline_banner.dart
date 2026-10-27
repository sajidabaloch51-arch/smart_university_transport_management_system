import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin banner when the device has no network — cached Firestore data still shows.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    try {
      _sub = Connectivity().onConnectivityChanged.listen((results) {
        final offline = results.every((r) => r == ConnectivityResult.none);
        if (mounted && offline != _offline) {
          setState(() => _offline = offline);
        }
      });
      Connectivity().checkConnectivity().then((results) {
        final offline = results.every((r) => r == ConnectivityResult.none);
        if (mounted) setState(() => _offline = offline);
      });
    } catch (_) {
      // Package optional at runtime — ignore if missing.
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_offline) return const SizedBox.shrink();
    return Material(
      color: Colors.orange.shade800,
      child: const SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Offline — showing cached data',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
