import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the real Google Maps app / website with live coordinates.
class MapsLauncherService {
  /// Show a single point in Google Maps.
  static Future<bool> openLocation({
    required double lat,
    required double lng,
    String label = 'Location',
  }) async {
    final encoded = Uri.encodeComponent(label);
    final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encoded)');
    final web = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    return _launchPreferNative(geo, web);
  }

  /// Turn-by-turn directions from [origin] to [destination] in Google Maps.
  static Future<bool> openDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String travelMode = 'driving',
  }) async {
    final native = Uri.parse(
      'google.navigation:q=$destLat,$destLng&mode=d',
    );
    final web = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$originLat,$originLng'
      '&destination=$destLat,$destLng'
      '&travelmode=$travelMode',
    );
    return _launchPreferNative(native, web);
  }

  /// Show student + bus together (bus as destination).
  static Future<bool> openBusTrackingInGoogleMaps({
    double? studentLat,
    double? studentLng,
    required double busLat,
    required double busLng,
    String busLabel = 'Live Bus',
  }) async {
    if (studentLat != null && studentLng != null) {
      return openDirections(
        originLat: studentLat,
        originLng: studentLng,
        destLat: busLat,
        destLng: busLng,
      );
    }
    return openLocation(lat: busLat, lng: busLng, label: busLabel);
  }

  static Future<bool> _launchPreferNative(Uri native, Uri fallback) async {
    try {
      if (await canLaunchUrl(native)) {
        return launchUrl(native, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Native Maps launch failed: $e');
    }
    try {
      if (await canLaunchUrl(fallback)) {
        return launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Web Maps launch failed: $e');
    }
    return false;
  }
}
