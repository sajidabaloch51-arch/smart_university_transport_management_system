import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/firestore_service.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final _firestoreService = FirestoreService();
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};

  // Default position: Gwadar University (approximate)
  static const _kGooglePlex = CameraPosition(
    target: LatLng(25.1450, 62.3600),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _subscribeToDriverLocation();
  }

  void _subscribeToDriverLocation() {
    // For demo, tracking 'driver_123'
    _firestoreService.getDriverLocation('driver_123').listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data['isOnDuty'] == true) {
          final lat = data['lat'] as double;
          final lng = data['lng'] as double;
          _updateMarker(lat, lng);
        } else {
          setState(() => _markers.remove(const MarkerId('driver_bus')));
        }
      }
    });
  }

  void _updateMarker(double lat, double lng) {
    final markerId = const MarkerId('driver_bus');
    final marker = Marker(
      markerId: markerId,
      position: LatLng(lat, lng),
      infoWindow: const InfoWindow(title: 'Bus Route A', snippet: 'Moving to University'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );

    setState(() {
      _markers[markerId] = marker;
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        markers: Set<Marker>.of(_markers.values),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mapController?.animateCamera(CameraUpdate.newCameraPosition(_kGooglePlex)),
        label: const Text('Center on UoG'),
        icon: const Icon(Icons.school),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
