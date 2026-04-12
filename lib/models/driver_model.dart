class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String vehicle;
  final double? latitude;
  final double? longitude;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    this.latitude,
    this.longitude,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id:        json['id'] ?? '',
      name:      json['name'] ?? '',
      phone:     json['phone'] ?? '',
      vehicle:   json['vehicle'] ?? '',
      latitude:  json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }
}
