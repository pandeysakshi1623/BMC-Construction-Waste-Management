class SiteModel {
  final String id;
  final String name;
  final String location;
  final double area;
  final double expectedWaste;
  final String qrCode;
  final String pickupStatus;
  final double actualWaste;

  SiteModel({
    required this.id,
    required this.name,
    required this.location,
    required this.area,
    required this.expectedWaste,
    required this.qrCode,
    required this.pickupStatus,
    required this.actualWaste,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      area: (json['area'] ?? 0).toDouble(),
      expectedWaste: (json['expected_waste'] ?? 0).toDouble(),
      qrCode: json['qr_code'] ?? '',
      pickupStatus: json['pickup_status'] ?? 'Pending',
      actualWaste: (json['actual_waste'] ?? 0).toDouble(),
    );
  }
}
