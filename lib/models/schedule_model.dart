class ScheduleModel {
  final String id;
  final String busNumber;
  final String routeName;
  final String departureTime;
  final String arrivalTime;
  final List<String> days;

  ScheduleModel({
    required this.id,
    required this.busNumber,
    required this.routeName,
    required this.departureTime,
    required this.arrivalTime,
    required this.days,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> map, String docId) {
    return ScheduleModel(
      id: docId,
      busNumber: map['busNumber'] ?? '',
      routeName: map['routeName'] ?? '',
      departureTime: map['departureTime'] ?? '',
      arrivalTime: map['arrivalTime'] ?? '',
      days: List<String>.from(map['days'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber,
      'routeName': routeName,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'days': days,
    };
  }
}
