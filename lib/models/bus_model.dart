class BusModel {
  final String id;
  final String busNumber;
  final int capacity;
  final String busModel;
  final String registrationNumber;
  final String assignedDriverId;
  final String assignedDriverName;
  final String assignedRouteId;
  final String assignedRouteName;
  final bool isActive;

  BusModel({
    required this.id,
    required this.busNumber,
    required this.capacity,
    required this.busModel,
    required this.registrationNumber,
    required this.assignedDriverId,
    required this.assignedDriverName,
    required this.assignedRouteId,
    required this.assignedRouteName,
    this.isActive = true,
  });

  factory BusModel.fromMap(Map<String, dynamic> map, String docId) {
    return BusModel(
      id: docId,
      busNumber: map['busNumber'] ?? '',
      capacity: map['capacity'] ?? 0,
      busModel: map['busModel'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      assignedDriverId: map['assignedDriverId'] ?? '',
      assignedDriverName: map['assignedDriverName'] ?? '',
      assignedRouteId: map['assignedRouteId'] ?? '',
      assignedRouteName: map['assignedRouteName'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber,
      'capacity': capacity,
      'busModel': busModel,
      'registrationNumber': registrationNumber,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'assignedRouteId': assignedRouteId,
      'assignedRouteName': assignedRouteName,
      'isActive': isActive,
    };
  }
}
