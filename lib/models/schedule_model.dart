class ScheduleModel {
  final String id;
  final String universityId;
  final String routeId;
  final String busId;
  final String driverId;
  final String direction; // toUniversity, fromUniversity
  final String departureTime;
  final String arrivalTime;
  final List<String> daysOfWeek;
  final bool isActive;

  ScheduleModel({
    required this.id,
    required this.universityId,
    required this.routeId,
    required this.busId,
    required this.driverId,
    required this.direction,
    required this.departureTime,
    required this.arrivalTime,
    required this.daysOfWeek,
    this.isActive = true,
  });

  factory ScheduleModel.fromMap(String id, Map<String, dynamic> map) {
    return ScheduleModel(
      id: id,
      universityId: map['universityId'] ?? '',
      routeId: map['routeId'] ?? '',
      busId: map['busId'] ?? '',
      driverId: map['driverId'] ?? '',
      direction: map['direction'] ?? '',
      departureTime: map['departureTime'] ?? '',
      arrivalTime: map['arrivalTime'] ?? '',
      daysOfWeek: List<String>.from(map['daysOfWeek'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'universityId': universityId,
      'routeId': routeId,
      'busId': busId,
      'driverId': driverId,
      'direction': direction,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'daysOfWeek': daysOfWeek,
      'isActive': isActive,
    };
  }
}
