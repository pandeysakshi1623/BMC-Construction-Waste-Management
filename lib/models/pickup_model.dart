/// All possible states a pickup can be in
enum PickupStatus { pending, accepted, inProgress, completed, failed }

extension PickupStatusExt on PickupStatus {
  String get value {
    switch (this) {
      case PickupStatus.pending:    return 'Pending';
      case PickupStatus.accepted:   return 'Accepted';
      case PickupStatus.inProgress: return 'In Progress';
      case PickupStatus.completed:  return 'Completed';
      case PickupStatus.failed:     return 'Failed';
    }
  }

  static PickupStatus fromString(String s) {
    switch (s.toLowerCase().replaceAll(' ', '')) {
      case 'accepted':   return PickupStatus.accepted;
      case 'inprogress': return PickupStatus.inProgress;
      case 'completed':  return PickupStatus.completed;
      case 'failed':     return PickupStatus.failed;
      default:           return PickupStatus.pending;
    }
  }
}

class PickupModel {
  final String id;
  final String siteId;
  final String siteName;
  final String location;
  final String scheduledDate;
  final PickupStatus status;
  final String qrCode;
  final String wasteType;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? driverVehicle;
  final String? notes;

  PickupModel({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.location,
    required this.scheduledDate,
    required this.status,
    required this.qrCode,
    required this.wasteType,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverVehicle,
    this.notes,
  });

  factory PickupModel.fromJson(Map<String, dynamic> json) {
    return PickupModel(
      id:            json['id'] ?? '',
      siteId:        json['site_id'] ?? '',
      siteName:      json['site_name'] ?? '',
      location:      json['location'] ?? '',
      scheduledDate: json['scheduled_date'] ?? '',
      status:        PickupStatusExt.fromString(json['status'] ?? 'Pending'),
      qrCode:        json['qr_code'] ?? '',
      wasteType:     json['waste_type'] ?? '',
      driverId:      json['driver_id'],
      driverName:    json['driver_name'],
      driverPhone:   json['driver_phone'],
      driverVehicle: json['driver_vehicle'],
      notes:         json['notes'],
    );
  }

  /// Returns a copy with a new status (used for local state updates)
  PickupModel copyWith({PickupStatus? status, String? notes}) {
    return PickupModel(
      id:            id,
      siteId:        siteId,
      siteName:      siteName,
      location:      location,
      scheduledDate: scheduledDate,
      status:        status ?? this.status,
      qrCode:        qrCode,
      wasteType:     wasteType,
      driverId:      driverId,
      driverName:    driverName,
      driverPhone:   driverPhone,
      driverVehicle: driverVehicle,
      notes:         notes ?? this.notes,
    );
  }
}
