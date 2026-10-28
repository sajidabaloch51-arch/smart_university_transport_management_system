import '../utils/firestore_parse.dart';

class BusModel {
  final String id;
  final String busNumber;
  final int? capacity;
  final String? busModel;
  final String registrationNumber;
  final String assignedDriverId;
  final String assignedDriverName;
  final String assignedRouteId;
  final String assignedRouteName;
  final bool isActive;

  BusModel({
    required this.id,
    required this.busNumber,
    this.capacity,
    this.busModel,
    this.registrationNumber = '',
    this.assignedDriverId = '',
    this.assignedDriverName = '',
    this.assignedRouteId = '',
    this.assignedRouteName = '',
    this.isActive = true,
  });

  static bool _hasValue(String? value) {
    if (value == null) return false;
    final v = value.trim();
    if (v.isEmpty) return false;
    if (v.toLowerCase() == 'not assigned') return false;
    return true;
  }

  factory BusModel.fromMap(Map<String, dynamic> map, String docId) {
    return BusModel(
      id: docId,
      busNumber: FirestoreParse.asString(map['busNumber']),
      capacity: FirestoreParse.asInt(map['capacity']),
      busModel: map['busModel'] == null
          ? null
          : FirestoreParse.asString(map['busModel']),
      registrationNumber: FirestoreParse.asString(map['registrationNumber']),
      assignedDriverId: FirestoreParse.asString(map['assignedDriverId']),
      assignedDriverName: FirestoreParse.asString(map['assignedDriverName']),
      assignedRouteId: FirestoreParse.asString(map['assignedRouteId']),
      assignedRouteName: FirestoreParse.asString(map['assignedRouteName']),
      isActive: FirestoreParse.asBool(map['isActive'], fallback: true),
    );
  }

  /// Lean Firestore payload — never writes empty / null / "Not Assigned" junk.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'busNumber': busNumber,
      'isActive': isActive,
    };

    if (_hasValue(registrationNumber)) {
      map['registrationNumber'] = registrationNumber.trim();
    }
    if (_hasValue(assignedDriverId)) {
      map['assignedDriverId'] = assignedDriverId.trim();
    }
    if (_hasValue(assignedDriverName)) {
      map['assignedDriverName'] = assignedDriverName.trim();
    }
    if (_hasValue(assignedRouteId)) {
      map['assignedRouteId'] = assignedRouteId.trim();
    }
    if (_hasValue(assignedRouteName)) {
      map['assignedRouteName'] = assignedRouteName.trim();
    }
    if (capacity != null) map['capacity'] = capacity;
    if (_hasValue(busModel)) map['busModel'] = busModel!.trim();

    return map;
  }
}
