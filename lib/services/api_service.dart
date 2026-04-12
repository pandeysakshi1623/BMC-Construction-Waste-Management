import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://your-api-base-url.com/api';

  /// Builds standard auth headers for all authenticated requests
  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // CONTRACTOR
  static Future<Map<String, dynamic>> registerSite({
    required String name,
    required String location,
    required double area,
    required double expectedWaste,
    String token = '',
  }) async {
    // TODO: Replace with real API call
    // final response = await http.post(
    //   Uri.parse('$baseUrl/contractor/sites'),
    //   headers: _authHeaders(token),
    //   body: jsonEncode({'name': name, 'location': location, 'area': area, 'expected_waste': expectedWaste}),
    // );
    await Future.delayed(const Duration(seconds: 1));
    return {
      'id': 'site_001',
      'name': name,
      'location': location,
      'area': area,
      'expected_waste': expectedWaste,
      'qr_code': 'QR_SITE_001_${DateTime.now().millisecondsSinceEpoch}',
      'pickup_status': 'Pending',
      'actual_waste': 0,
    };
  }

  static Future<List<Map<String, dynamic>>> getContractorSites({
    String token = '',
  }) async {
    // TODO: Replace with real API call
    // final response = await http.get(
    //   Uri.parse('$baseUrl/contractor/sites'),
    //   headers: _authHeaders(token),
    // );
    // return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    await Future.delayed(const Duration(seconds: 1));
    return [
      {
        'id': 'site_001',
        'name': 'Downtown Tower A',
        'location': 'Main St, Block 5',
        'area': 2500.0,
        'expected_waste': 120.0,
        'qr_code': 'QR_SITE_001',
        'pickup_status': 'Scheduled',
        'actual_waste': 85.0,
      },
      {
        'id': 'site_002',
        'name': 'Riverside Complex',
        'location': 'River Rd, Block 2',
        'area': 1800.0,
        'expected_waste': 90.0,
        'qr_code': 'QR_SITE_002',
        'pickup_status': 'Pending',
        'actual_waste': 0.0,
      },
    ];
  }

  static Future<bool> schedulePickup(String siteId, String date, {
    String token = '',
  }) async {
    // TODO: Replace with real API call
    // await http.post(
    //   Uri.parse('$baseUrl/contractor/schedule-pickup'),
    //   headers: _authHeaders(token),
    //   body: jsonEncode({'site_id': siteId, 'date': date}),
    // );
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  /// Returns pickups for contractor view — includes driver info per site
  static Future<List<Map<String, dynamic>>> getContractorPickups({
    String token = '',
  }) async {
    // TODO: Replace with real API call
    // final response = await http.get(
    //   Uri.parse('$baseUrl/contractor/pickups'),
    //   headers: _authHeaders(token),
    // );
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': 'p001',
        'site_id': 'site_001',
        'site_name': 'Downtown Tower A',
        'location': 'Main St, Block 5',
        'scheduled_date': '2024-06-10',
        'status': 'Accepted',
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
        'driver_id': 'd02',
        'driver_name': 'Khalid Al-Otaibi',
        'driver_phone': '+966509876543',
        'driver_vehicle': 'Truck - XYZ 5678',
      },
    ];
  }

  static Future<bool> uploadProof(String siteId, String imagePath, double quantity, {
    String token = '',
  }) async {
    // TODO: Replace with real API call (use multipart for image)
    // final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/contractor/upload-proof'))
    //   ..headers.addAll(_authHeaders(token))
    //   ..fields['site_id'] = siteId
    //   ..fields['quantity'] = quantity.toString()
    //   ..files.add(await http.MultipartFile.fromPath('image', imagePath));
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // AUTH
  static Future<Map<String, dynamic>> login(String email, String password) async {
    // TODO: Replace with real API call
    await Future.delayed(const Duration(seconds: 1));
    return {
      'id': '123',
      'email': email,
      'token': 'dummy_token_abc',
      'role': '',
    };
  }

  // CITIZEN
  static Future<bool> submitComplaint({
    required String description,
    required double latitude,
    required double longitude,
    required String imagePath,
    String token = '',
  }) async {
    // TODO: Replace with real API call (use multipart for image)
    // final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/complaints'))
    //   ..headers.addAll(_authHeaders(token))
    //   ..fields['description'] = description
    //   ..fields['latitude'] = latitude.toString()
    //   ..fields['longitude'] = longitude.toString()
    //   ..files.add(await http.MultipartFile.fromPath('image', imagePath));
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  static Future<List<Map<String, dynamic>>> getComplaints({
    String token = '',
  }) async {
    // TODO: Replace with real API call
    // final response = await http.get(
    //   Uri.parse('$baseUrl/citizen/complaints'),
    //   headers: _authHeaders(token),
    // );
    await Future.delayed(const Duration(seconds: 1));
    return [
      {
        'id': 'c001',
        'description': 'Illegal dumping near school',
        'latitude': 24.7136,
        'longitude': 46.6753,
        'status': 'Under Review',
        'created_at': '2024-06-01',
        'image_url': '',
      },
      {
        'id': 'c002',
        'description': 'Construction debris blocking road',
        'latitude': 24.7200,
        'longitude': 46.6800,
        'status': 'Resolved',
        'created_at': '2024-05-28',
        'image_url': '',
      },
      {
        'id': 'c003',
        'description': 'Waste pile near residential area',
        'latitude': 24.7100,
        'longitude': 46.6700,
        'status': 'Pending',
        'created_at': '2024-06-03',
        'image_url': '',
      },
    ];
  }

  // DRIVER
  static Future<List<Map<String, dynamic>>> getAssignedPickups({
    String token = '',
  }) async {
    // TODO: Replace with real API call
    // final response = await http.get(
    //   Uri.parse('$baseUrl/driver/pickups'),
    //   headers: _authHeaders(token),
    // );
    await Future.delayed(const Duration(seconds: 1));
    return [
      {
        'id': 'p001',
        'site_name': 'Downtown Tower A',
        'location': 'Main St, Block 5',
        'scheduled_date': '2024-06-10',
        'status': 'Pending',
        'qr_code': 'QR_SITE_001',
        'waste_type': 'Construction Debris',
      },
      {
        'id': 'p002',
        'site_name': 'Riverside Complex',
        'location': 'River Rd, Block 2',
        'scheduled_date': '2024-06-11',
        'status': 'Completed',
        'qr_code': 'QR_SITE_002',
        'waste_type': 'Mixed Waste',
      },
    ];
  }

  static Future<bool> validateQrCode(String qrCode, {
    String token = '',
  }) async {
    // TODO: Replace with real API call
    // final response = await http.post(
    //   Uri.parse('$baseUrl/driver/validate-qr'),
    //   headers: _authHeaders(token),
    //   body: jsonEncode({'qr_code': qrCode}),
    // );
    await Future.delayed(const Duration(milliseconds: 800));
    return qrCode.startsWith('QR_SITE_');
  }

  static Future<bool> uploadDisposalProof(
      String pickupId, String imagePath, {
    String token = '',
  }) async {
    // TODO: Replace with real API call (use multipart for image)
    // final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/driver/disposal-proof'))
    //   ..headers.addAll(_authHeaders(token))
    //   ..fields['pickup_id'] = pickupId
    //   ..files.add(await http.MultipartFile.fromPath('image', imagePath));
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
