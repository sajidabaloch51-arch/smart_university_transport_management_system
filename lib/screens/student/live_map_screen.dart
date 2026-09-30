import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../services/firestore_service.dart';
import '../../services/maps_service.dart';
import '../../services/location_service.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final _firestoreService = FirestoreService();
  final _mapsService = MapsService();
  final _locationService = LocationService();
  
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};
  String _etaText = "Locating bus...";
  bool _myLocationEnabled = false;

  // Default position: Gwadar University
  static const _kGooglePlex = CameraPosition(
    target: LatLng(25.1450, 62.3600),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    
    // Only subscribe if Firebase is ready
    if (Firebase.apps.isNotEmpty) {
      _subscribeToDriverLocation();
    } else {
      setState(() {
        _etaText = "Syncing with cloud...";
      });
    }
  }

  void _checkPermissions() async {
    try {
      bool hasPermission = await _locationService.checkPermissions();
      if (hasPermission && mounted) {
        setState(() {
          _myLocationEnabled = true;
        });
      }
    } catch (e) {
      debugPrint("Permission check failed: $e");
    }
  }

  void _subscribeToDriverLocation() {
    try {
      // Tracking 'driver_123' as an example
      _firestoreService.getDriverLocation('driver_123').listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          if (data['isOnDuty'] == true) {
            final lat = data['lat'] as double;
            final lng = data['lng'] as double;
            _updateMarker(lat, lng);
          } else {
            if (mounted) {
              setState(() {
                _markers.remove(const MarkerId('driver_bus'));
                _etaText = "Bus is offline";
              });
            }
          }
        }
      }, onError: (e) {
        debugPrint("Error listening to location: $e");
      });
    } catch (e) {
      debugPrint("Subscription failed: $e");
    }
  }

  void _updateMarker(double lat, double lng) {
    final driverPos = LatLng(lat, lng);
    final universityPos = _kGooglePlex.target;
    final eta = _mapsService.getETAString(driverPos, universityPos);
    
    const markerId = MarkerId('driver_bus');
    final marker = Marker(
      markerId: markerId,
      position: driverPos,
      infoWindow: InfoWindow(
        title: 'Bus Route A', 
        snippet: eta,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );

    if (mounted) {
      setState(() {
        _markers[markerId] = marker;
        _etaText = "Bus arrives in: $eta";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,
            markers: Set<Marker>.of(_markers.values),
            myLocationEnabled: _myLocationEnabled,
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus, color: Color(0xFF1565C0)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      _etaText,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mapController?.animateCamera(CameraUpdate.newCameraPosition(_kGooglePlex)),
        label: const Text('Center on UoG'),
        icon: const Icon(Icons.school),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
