import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pickup_model.dart';

class PickupService {
  static const String _baseUrl = 'https://your-api-base-url.com/api';

  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<List<PickupModel>> getAssignedPickups({
    String token = '',
  }) async {
    // TODO: Replace with real API call
    // final res = await http.get(
    //   Uri.parse('$_baseUrl/driver/pickups'),
    //   headers: _authHeaders(token),
    // );
    // return (jsonDecode(res.body) as List)
    //     .map((e) => PickupModel.fromJson(e))
    //     .toList();
    await Future.delayed(const Duration(seconds: 1));

    final dummy = [
      {
        'id': 'p001',
        'site_id': 'site_001',
        'site_name': 'Downtown Tower A',
        'location': 'Main St, Block 5',
        'scheduled_date': '2024-06-10',
        'status': 'Pending',
        'qr_code': 'QR_SITE_001',
        'waste_type': 'Construction Debris',
        'driver_id': 'd01',
        'driver_name': 'Ahmed Al-Rashid',
        'driver_phone': '+966501234567',
        'driver_vehicle': 'Truck - ABC 1234',
      },
      {
        'id': 'p002',
        'site_id': 'site_002',
        'site_name': 'Riverside Complex',
        'location': 'River Rd, Block 2',
        'scheduled_date': '2024-06-11',
        'status': 'Completed',
        'qr_code': 'QR_SITE_002',
        'waste_type': 'Mixed Waste',
        'driver_id': 'd01',
        'driver_name': 'Ahmed Al-Rashid',
        'driver_phone': '+966501234567',
        'driver_vehicle': 'Truck - ABC 1234',
      },
      {
        'id': 'p003',
        'site_id': 'site_003',
        'site_name': 'North Bridge Project',
        'location': 'Industrial Zone, Gate 3',
        'scheduled_date': '2024-06-12',
        'status': 'Accepted',
        'qr_code': 'QR_SITE_003',
        'waste_type': 'Hazardous Waste',
        'driver_id': 'd01',
        'driver_name': 'Ahmed Al-Rashid',
        'driver_phone': '+966501234567',
        'driver_vehicle': 'Truck - ABC 1234',
      },
    ];

    return dummy.map((e) => PickupModel.fromJson(e)).toList();
  }

  static Future<bool> updatePickupStatus(
    String pickupId,
    String status, {
    String? notes,
    String token = '',
  }) async {
    // TODO: Replace with real API call
    // await http.patch(
    //   Uri.parse('$_baseUrl/driver/pickups/$pickupId/status'),
    //   headers: _authHeaders(token),
    //   body: jsonEncode({'status': status, 'notes': notes}),
    // );
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }

  static Future<bool> uploadDisposalProof(
      String pickupId, String imagePath, {
    String token = '',
  }) async {
    // TODO: Replace with real multipart API call
    // final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/driver/disposal-proof'))
    //   ..headers.addAll(_authHeaders(token))
    //   ..fields['pickup_id'] = pickupId
    //   ..files.add(await http.MultipartFile.fromPath('image', imagePath));
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
