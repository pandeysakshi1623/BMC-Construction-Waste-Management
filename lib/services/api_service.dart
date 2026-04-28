import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  /// Change this one constant to switch environments.
  /// - Chrome / macOS desktop / iOS sim → http://localhost:8000
  /// - Android emulator                 → http://10.0.2.2:8000
  /// - Real device (LAN)                → http://192.168.x.x:8000
  static const String _base = 'http://localhost:8000';

  /// Same base used for image URLs (static files served by FastAPI)
  static String get base => _base;

  static const Duration _timeout = Duration(seconds: 12);

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
    final url = '$_base/alerts/$endpoint';
    final response = await http.get(
      Uri.parse(url),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    } else {
      throw Exception(_errorMessage(response, 'Failed to load alerts'));
    }
  }

  // BMC
  static Future<Map<String, dynamic>> getBmcDashboard({
    String token = '',
  }) async {
    final url = '$_base/bmc/dashboard';
    final response = await http.get(
      Uri.parse(url),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    }
    throw Exception(_errorMessage(response, 'Failed to load BMC dashboard'));
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
    final url = '$_base/bmc/trucks/$pickupId/approve';
    final response = await http.post(
      Uri.parse(url),
      headers: _authHeaders(token),
      body: jsonEncode({'status': status}),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      throw Exception(_errorMessage(response, 'Failed to update truck status'));
    }
  }

  static Future<List<Map<String, dynamic>>> getBmcPickups({
    String token = '',
  }) async {
    // Uses /pickups/all — no contractor auth required, works with BMC token
    final url = '$_base/pickups/all';
    final response = await http.get(
      Uri.parse(url),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    }
    throw Exception(_errorMessage(response, 'Failed to load pickups'));
  }

  static Future<List<Map<String, dynamic>>> getBmcComplaints({
    String token = '',
  }) async {
    final url = '$_base/citizen/queries/all';
    final response = await http.get(
      Uri.parse(url),
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


    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();

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

  /// BMC: Approve or reject a complaint. On approve, optionally creates penalty.
  static Future<Map<String, dynamic>> resolveComplaint(
    String queryId, {
    required String action, // 'approve' or 'reject'
    String? reason,
    double? penaltyAmount,
    String token = '',
  }) async {
    final response = await http.post(
      Uri.parse('$_base/citizen/complaints/resolve/$queryId'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'action': action,
        if (reason != null) 'reason': reason,
        if (penaltyAmount != null) 'penalty_amount': penaltyAmount,
      }),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_errorMessage(response, 'Failed to resolve complaint'));
  }

  static Future<List<Map<String, dynamic>>> getContractorPenalties({
    required String contractorId,
    String token = '',
  }) async {
    final response = await http.get(
      Uri.parse('$_base/bmc/penalties/contractor/$contractorId'),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Get penalties grouped by site (for BMC and contractor views)
  static Future<List<Map<String, dynamic>>> getPenaltiesBySite({
    String token = '',
  }) async {
    final response = await http.get(
      Uri.parse('$_base/bmc/penalties/by-site'),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // PROFILE
  static Future<Map<String, dynamic>> getProfile({
    required String role,
    String token = '',
  }) async {
    // BMC officials don't have a profile endpoint — return a stub
    if (role == 'bmc') {
      return {'name': 'BMC Official', 'contact': '', 'email': 'admin@bmc.gov'};
    }
    final endpoint = (role == 'citizen') ? 'citizen' : 'contractor';
    final url = '$_base/profile/$endpoint';
    final response = await http.get(
      Uri.parse(url),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    }
    throw Exception(_errorMessage(response, 'Failed to load profile'));
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String role,
    String token = '',
    String name = '',
    String contact = '',
    String email = '',
    String companyName = '',
    String address = '',
  }) async {
    // BMC officials don't have an editable profile endpoint
    if (role == 'bmc') {
      throw Exception('BMC profile editing is not supported.');
    }
    final endpoint = (role == 'citizen') ? 'citizen' : 'contractor';
    final body = <String, dynamic>{};
    if (name.isNotEmpty)        body['name']         = name;
    if (contact.isNotEmpty)     body['contact']      = contact;
    if (email.isNotEmpty)       body['email']        = email;
    if (companyName.isNotEmpty) body['company_name'] = companyName;
    if (address.isNotEmpty)     body['address']      = address;

    final url = '$_base/profile/$endpoint';
    final response = await http.put(
      Uri.parse(url),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    }
    throw Exception(_errorMessage(response, 'Failed to update profile'));
  }

  static Future<void> deleteProfile({
    required String role,
    String token = '',
  }) async {
    if (role == 'bmc') {
      throw Exception('BMC account deletion is not supported.');
    }
    final endpoint = (role == 'citizen') ? 'citizen' : 'contractor';
    final url = '$_base/profile/$endpoint';
    final response = await http.delete(
      Uri.parse(url),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      throw Exception(_errorMessage(response, 'Failed to delete account'));
    }
  }

  static Future<List<Map<String, dynamic>>> getPickupProofHistory({
    String token = '',
  }) async {
    final url = '$_base/pickups/proof-history';
    final response = await http.get(
      Uri.parse(url),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    }
    throw Exception(_errorMessage(response, 'Failed to load proof history'));
  }

  // DRIVER LOCATION + RATING
  static Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    String token = '',
  }) async {
    final url = '$_base/driver/location';
    await http.post(
      Uri.parse(url),
      headers: _authHeaders(token),
      body: jsonEncode({
        'driver_id': driverId,
        'latitude': latitude,
        'longitude': longitude,
      }),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
  }

  static Future<Map<String, dynamic>?> getDriverLocation(String driverId, {String token = ''}) async {
    final url = '$_base/driver/location/$driverId';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: _authHeaders(token),
      ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
      return null; // 404 = no location yet
    } catch (_) {
      return null;
    }
  }

  static Future<void> submitDriverRating({
    required String driverId,
    required int rating,
    String review = '',
    String token = '',
  }) async {
    final url = '$_base/driver/rating';
    final res = await http.post(
      Uri.parse(url),
      headers: _authHeaders(token),
      body: jsonEncode({'driver_id': driverId, 'rating': rating, 'review': review}),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_errorMessage(res, 'Failed to submit rating'));
    }
  }

  // DRIVER
  static Future<List<Map<String, dynamic>>> getAssignedPickups({
    String token = '',
  }) async {
    final response = await http.get(
      Uri.parse('$_base/pickups/driver'),
      headers: _authHeaders(token),
    ).timeout(_timeout, onTimeout: () => throw const SocketException('Connection timed out.'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(_errorMessage(response, 'Failed to load pickups'));
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


    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return true;
    } else {
      throw Exception(_errorMessageFromString(responseBody, 'Upload failed'));
    }
  }
}
