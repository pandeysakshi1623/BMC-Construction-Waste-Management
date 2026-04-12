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
      // backend uses 'site_name', fallback to 'name' for dummy compatibility
      name: json['site_name'] ?? json['name'] ?? '',
      location: json['location'] ?? '',
      area: (json['area'] ?? 0).toDouble(),
      // backend uses 'waste_estimated', fallback to 'expected_waste'
      expectedWaste: (json['waste_estimated'] ?? json['expected_waste'] ?? 0).toDouble(),
      qrCode: json['qr_code'] ?? '',
      pickupStatus: json['pickup_status'] ?? 'Pending',
      // backend uses 'waste_actual', fallback to 'actual_waste'
      actualWaste: (json['waste_actual'] ?? json['actual_waste'] ?? 0).toDouble(),
    );
  }
}
