class BusModel {
  final String id;
  final String universityId;
  final String busNumber;
  final int capacity;
  final String assignedRouteId;
  final String assignedDriverId;
  final bool isActive;

  BusModel({
    required this.id,
    required this.universityId,
    required this.busNumber,
    required this.capacity,
    required this.assignedRouteId,
    required this.assignedDriverId,
    this.isActive = true,
  });

  factory BusModel.fromMap(String id, Map<String, dynamic> map) {
    return BusModel(
      id: id,
      universityId: map['universityId'] ?? '',
      busNumber: map['busNumber'] ?? '',
      capacity: map['capacity'] ?? 0,
      assignedRouteId: map['assignedRouteId'] ?? '',
      assignedDriverId: map['assignedDriverId'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'universityId': universityId,
      'busNumber': busNumber,
      'capacity': capacity,
      'assignedRouteId': assignedRouteId,
      'assignedDriverId': assignedDriverId,
      'isActive': isActive,
    };
  }
}
