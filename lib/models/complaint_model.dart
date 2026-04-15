class ComplaintModel {
  final String id;
  final String description;
  final String location;
  final String status;
  final String createdAt;
  // lat/lng optional — only present in legacy dummy data
  final double latitude;
  final double longitude;

  ComplaintModel({
    required this.id,
    required this.description,
    required this.location,
    required this.status,
    required this.createdAt,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      // backend returns 'query_id', fallback to 'id'
      id: json['query_id'] ?? json['id'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: json['created_at'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
}
