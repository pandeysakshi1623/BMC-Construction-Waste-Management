class ComplaintModel {
  final String id;
  final String description;
  final double latitude;
  final double longitude;
  final String status;
  final String createdAt;
  final String imageUrl;

  ComplaintModel({
    required this.id,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    required this.imageUrl,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      status: json['status'] ?? 'Pending',
      createdAt: json['created_at'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}
