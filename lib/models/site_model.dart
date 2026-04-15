class SiteModel {
  final String id;
  final String name;
  final String location;
  final double area;
  final double expectedWaste;
  final String qrCode;       // short site_id used for scanning
  final String qrCodeUrl;    // full URL to QR image from backend
  final String pickupStatus;
  final double actualWaste;

  SiteModel({
    required this.id,
    required this.name,
    required this.location,
    required this.area,
    required this.expectedWaste,
    required this.qrCode,
    this.qrCodeUrl = '',
    required this.pickupStatus,
    required this.actualWaste,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'] ?? json['site_id'] ?? '',
      name: json['site_name'] ?? json['name'] ?? '',
      location: json['location'] ?? '',
      area: (json['area'] ?? json['plot_size'] ?? 0).toDouble(),
      expectedWaste:
          (json['waste_estimated'] ?? json['expected_waste'] ?? 0).toDouble(),
      qrCode: json['qr_code'] ?? json['site_id'] ?? '',
      qrCodeUrl: json['qr_code_url'] ?? '',
      pickupStatus: json['pickup_status'] ?? 'Pending',
      actualWaste:
          (json['waste_actual'] ?? json['actual_waste'] ?? 0).toDouble(),
    );
  }
}
