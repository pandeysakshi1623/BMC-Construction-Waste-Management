import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  /// Base URL for the backend.
  /// - macOS desktop / Chrome → http://localhost:8000
  /// - Android emulator       → http://10.0.2.2:8000
  /// - Real device (same WiFi)→ http://192.168.1.7:8000
  // static const String _base = 'http://192.168.171.18:8000';
  static const String _base = 'http://127.0.0.1:8000';

  /// Public base URL — used by screens to build full image URLs
  static String get base => _base;

  static const Duration _timeout = Duration(seconds: 10);

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
    required String role,
    String token = '',
  }) async {
    final endpoint = role == 'contractor' ? 'contractor' : 'bmc';
    final response = await http.get(
      Uri.parse('$_base/alerts/$endpoint'),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));

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
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
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
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_errorMessage(response, 'Site not found'));
    }
  }

  /// Public QR lookup — no auth required. Used by Citizen + BMC scanners.
  static Future<Map<String, dynamic>> getSiteByQrPublic(String siteId) async {
    final response = await http.get(
      Uri.parse('$_base/sites/by-qr/$siteId'),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
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
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_errorMessage(response, 'Failed to add penalty'));
    }
  }

  static Future<void> approveTruck(
      String pickupId, String status, {String token = ''}) async {
    final response = await http.post(
      Uri.parse('$_base/bmc/trucks/$pickupId/approve'),
      headers: _authHeaders(token),
      body: jsonEncode({'status': status}),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_errorMessage(response, 'Failed to update truck status'));
    }
  }

  static Future<List<Map<String, dynamic>>> getBmcPickups({
    String token = '',
  }) async {
    final response = await http.get(
      Uri.parse('$_base/pickups/contractor'),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(_errorMessage(response, 'Failed to load pickups'));
  }

  static Future<List<Map<String, dynamic>>> getBmcComplaints({
    String token = '',
  }) async {
    final response = await http.get(
      Uri.parse('$_base/citizen/queries/all'),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    // Fallback — BMC complaints endpoint may not exist yet
    return [];
  }

  // CONTRACTOR
  static Future<Map<String, dynamic>> registerSite({
    required String name,
    required String location,
    required String area,
    String token = '',
  }) async {
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
        'project_type': 'Construction',
        'plot_size': plotSize,
      }),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));

    print('Register Site Response: ${response.body}');

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
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));

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
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception(_errorMessage(response, 'Failed to schedule pickup'));
    }
  }

  static Future<List<Map<String, dynamic>>> getContractorPickups({
    String token = '',
  }) async {
    final response = await http.get(
      Uri.parse('$_base/pickups/contractor'),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(_errorMessage(response, 'Failed to load pickups'));
  }

  static Future<String?> uploadProof(
      String siteId, String imagePath, double quantity, {
    String token = '',
    Uint8List? imageBytes,
    String? imageName,
    bool driverVerified = false,
  }) async {
    if (siteId.isEmpty) throw Exception('Site ID is required');
    if (imageBytes == null) throw Exception('Image is required');

    print('SITE ID: $siteId');
    print('IMAGE PATH: $imagePath');
    print('ACTUAL WASTE: $quantity');
    print('DRIVER VERIFIED: $driverVerified');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/sites/upload-proof'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['site_id'] = siteId;
    request.fields['actual_waste'] = quantity.toStringAsFixed(2);
    request.fields['driver_verified'] = driverVerified.toString();

    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: imageName ?? 'photo.jpg',
    ));

    print('Sending fields: ${request.fields}');
    print('Sending file: ${imageName ?? 'photo.jpg'}');

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();
    print('Upload Response: $responseBody');

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      final decoded = jsonDecode(responseBody);
      return decoded['image_url'] as String?;
    } else {
      throw Exception(_errorMessageFromString(responseBody, 'Upload failed'));
    }
  }

  static Future<List<Map<String, dynamic>>> getProofHistory(
      String siteId, {String token = ''}) async {
    final response = await http.get(
      Uri.parse('$_base/sites/proof-history/$siteId'),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));

    print('Proof history response: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(_errorMessage(response, 'Failed to load proof history'));
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
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out. Check your network or server.'));
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
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out. Check your network or server.'));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_errorMessage(response, 'Signup failed'));
    }
  }

  /// Driver signup — dedicated endpoint, no email/company required
  static Future<void> signupDriver({
    required String username,
    required String password,
    required String name,
    required String contact,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/auth/signup/driver'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'name': name,
        'contact': contact,
      }),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out. Check your network or server.'));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_errorMessage(response, 'Signup failed'));
    }
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out. Check your network or server.'));
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
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out. Check your network or server.'));
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
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out. Check your network or server.'));
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
    String siteId = '',
  }) async {
    final response = await http.post(
      Uri.parse('$_base/citizen/query'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'description': description,
        'location': location,
        if (siteId.isNotEmpty) 'site_id': siteId,
      }),
    ).timeout(_timeout,
        onTimeout: () =>
            throw const SocketException('Connection timed out.'));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_errorMessage(response, 'Failed to submit complaint'));
    }
  }

  static Future<List<Map<String, dynamic>>> getComplaints({
    String token = '',
  }) async {
    final response = await http.get(
      Uri.parse('$_base/citizen/queries'),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(_errorMessage(response, 'Failed to load complaints'));
    }
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

  static Future<bool> validateQrCode(String qrCode, {String token = ''}) async {
    // QR codes are site IDs — validate by checking if site exists
    try {
      final response = await http.get(
        Uri.parse('$_base/bmc/qr-scan/$qrCode'),
        headers: _authHeaders(token),
      ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> uploadDisposalProof(
      String pickupId, String imagePath, {
    String token = '',
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    if (pickupId.isEmpty) throw Exception('Pickup ID is required');
    if (imageBytes == null) throw Exception('Image is required');

    print('PICKUP ID: $pickupId');
    print('IMAGE PATH: $imagePath');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/pickups/upload-proof'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['pickup_id'] = pickupId;

    // Use fromBytes for BOTH web and mobile
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: imageName ?? 'photo.jpg',
    ));

    print('Sending fields: ${request.fields}');
    print('Sending file: ${imageName ?? 'photo.jpg'}');

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();
    print('Upload Response: $responseBody');

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return true;
    } else {
      throw Exception(_errorMessageFromString(responseBody, 'Upload failed'));
    }
  }
}
