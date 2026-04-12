import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _base = 'http://10.24.41.1:8000';

  /// Builds standard auth headers for all authenticated requests
  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Extracts error message from response body, falls back to generic message
  static String _errorMessage(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      return body['detail'] ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// Returns true if response is 401 Unauthorized
  static bool isUnauthorized(http.Response response) =>
      response.statusCode == 401;

  // ALERTS
  static Future<List<Map<String, dynamic>>> getAlerts({
    required String role, // 'contractor' or 'bmc'
    String token = '',
  }) async {
    final endpoint = role == 'contractor' ? 'contractor' : 'bmc';
    final response = await http.get(
      Uri.parse('$_base/alerts/$endpoint'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(_errorMessage(response, 'Failed to load alerts'));
    }
  }

  // BMC
  static Future<Map<String, dynamic>> getBmcDashboard({
    String token = '',
  }) async {
    final response = await http.get(
      Uri.parse('$_base/bmc/dashboard'),
      headers: _authHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_errorMessage(response, 'Failed to load BMC dashboard'));
    }
  }

  static Future<Map<String, dynamic>> getSiteByQr(
      String siteId, {String token = ''}) async {
    final response = await http.get(
      Uri.parse('$_base/bmc/qr-scan/$siteId'),
      headers: _authHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_errorMessage(response, 'Site not found'));
    }
  }

  static Future<void> addPenalty(
      String siteId, double amount, String reason, {String token = ''}) async {
    final response = await http.post(
      Uri.parse('$_base/bmc/penalties/$siteId'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'penalty_cost_rupees': amount,
        'reason': reason,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_errorMessage(response, 'Failed to add penalty'));
    }
  }

  static Future<void> approveTruck(
      String pickupId, String status, {String token = ''}) async {
    // status: 'Approved' or 'Rejected'
    final response = await http.post(
      Uri.parse('$_base/bmc/trucks/$pickupId/approve'),
      headers: _authHeaders(token),
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_errorMessage(response, 'Failed to update truck status'));
    }
  }

  static Future<List<Map<String, dynamic>>> getBmcPickups({
    String token = '',
  }) async {
    // TODO: Replace with backend API when available — GET /bmc/pickups
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': 'p001',
        'site_name': 'Downtown Tower A',
        'location': 'Main St, Block 5',
        'scheduled_date': '2024-06-10',
        'status': 'Pending',
        'driver_name': 'Ahmed Al-Rashid',
        'driver_vehicle': 'Truck - ABC 1234',
      },
      {
        'id': 'p002',
        'site_name': 'Riverside Complex',
        'location': 'River Rd, Block 2',
        'scheduled_date': '2024-06-11',
        'status': 'Completed',
        'driver_name': 'Khalid Al-Otaibi',
        'driver_vehicle': 'Truck - XYZ 5678',
      },
    ];
  }

  static Future<List<Map<String, dynamic>>> getBmcComplaints({
    String token = '',
  }) async {
    // TODO: Replace with backend API when available — GET /bmc/complaints
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': 'c001',
        'description': 'Illegal dumping near school',
        'site_id': 'site_001',
        'citizen_id': 'user_123',
        'status': 'Under Review',
        'created_at': '2024-06-01',
      },
      {
        'id': 'c002',
        'description': 'Construction debris blocking road',
        'site_id': 'site_002',
        'citizen_id': 'user_456',
        'status': 'Resolved',
        'created_at': '2024-05-28',
      },
    ];
  }

  // CONTRACTOR
  static Future<Map<String, dynamic>> registerSite({
    required String name,
    required String location,
    required String area, // kept as String for safe int parsing
    String token = '',
  }) async {
    // Safe parse — validate before sending
    final plotSize = int.tryParse(area.trim());
    if (plotSize == null) {
      throw Exception('Area must be a valid whole number');
    }

    final response = await http.post(
      Uri.parse('$_base/sites/register'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'site_name': name,
        'location': location,
        'project_type': 'Construction', // default value
        'plot_size': plotSize,
      }),
    );

    print('Register Site Response: ${response.body}'); // debug

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_errorMessage(response, 'Failed to register site'));
    }
  }

  static Future<List<Map<String, dynamic>>> getContractorSites({
    String token = '',
  }) async {
    final response = await http.get(
      Uri.parse('$_base/sites/all'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(_errorMessage(response, 'Failed to load sites'));
    }
  }

  static Future<bool> schedulePickup(String siteId, String date, {
    String token = '',
  }) async {
    final response = await http.post(
      Uri.parse('$_base/pickups/request'),
      headers: _authHeaders(token),
      body: jsonEncode({'site_id': siteId, 'scheduled_date': date}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception(_errorMessage(response, 'Failed to schedule pickup'));
    }
  }

  /// Returns pickups for contractor view — includes driver info per site
  static Future<List<Map<String, dynamic>>> getContractorPickups({
    String token = '',
  }) async {
    // TODO: Replace with backend API when available — GET /pickups/contractor
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

  static Future<bool> uploadProof(
      String siteId, String imagePath, double quantity, {
    String token = '',
  }) async {
    print('Uploading image: $imagePath'); // debug

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/sites/upload-proof'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['site_id'] = siteId;
    request.fields['actual_waste'] = quantity.toString();
    request.files.add(
      await http.MultipartFile.fromPath('image', imagePath),
    );

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();
    print('Upload Response: $responseBody'); // debug

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return true;
    } else {
      throw Exception(_errorMessageFromString(responseBody, 'Upload failed'));
    }
  }

  /// Parses error detail from a raw JSON string
  static String _errorMessageFromString(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      return decoded['detail'] ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  // AUTH
  /// Contractor signup → POST /auth/signup
  static Future<void> signupContractor({
    required String username,
    required String password,
    required String name,
    required String contact,
    required String address,
    required String email,
    required String companyName,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'name': name,
        'contact': contact,
        'address': address,
        'email': email,
        'company_name': companyName,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_errorMessage(response, 'Signup failed'));
    }
  }

  /// Citizen signup → POST /citizen/signup
  static Future<void> signupCitizen({
    required String username,
    required String password,
    required String name,
    required String contact,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/citizen/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'name': name,
        'contact': contact,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_errorMessage(response, 'Signup failed'));
    }
  }

  /// Driver signup — uses same endpoint as contractor
  static Future<void> signupDriver({
    required String username,
    required String password,
    required String name,
    required String contact,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'name': name,
        'contact': contact,
        'address': '',
        'email': '',
        'company_name': '',
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_errorMessage(response, 'Signup failed'));
    }
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_errorMessage(response, 'Login failed'));
    }
  }

  static Future<Map<String, dynamic>> loginCitizen(
      String username, String password) async {
    final response = await http.post(
      Uri.parse('$_base/citizen/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_errorMessage(response, 'Login failed'));
    }
  }

  static Future<Map<String, dynamic>> loginBmc(
      String username, String password) async {
    final response = await http.post(
      Uri.parse('$_base/bmc/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_errorMessage(response, 'Login failed'));
    }
  }

  // CITIZEN
  static Future<void> submitComplaint({
    required String description,
    required String location,
    String token = '',
  }) async {
    final response = await http.post(
      Uri.parse('$_base/citizen/query'),
      headers: _authHeaders(token),
      body: jsonEncode({'description': description, 'location': location}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_errorMessage(response, 'Failed to submit complaint'));
    }
  }

  static Future<List<Map<String, dynamic>>> getComplaints({
    String token = '',
  }) async {
    // TODO: Replace with backend API when available — GET /citizen/queries
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
    // TODO: Replace with backend API when available — GET /pickups/driver
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
    print('Uploading image: $imagePath'); // debug

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/pickups/upload-proof'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['pickup_id'] = pickupId;
    request.files.add(
      await http.MultipartFile.fromPath('image', imagePath),
    );

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();
    print('Upload Response: $responseBody'); // debug

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return true;
    } else {
      throw Exception(_errorMessageFromString(responseBody, 'Upload failed'));
    }
  }
}
