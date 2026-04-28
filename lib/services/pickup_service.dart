import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/pickup_model.dart';
import 'api_service.dart';

class PickupService {
  static const Duration _timeout = Duration(seconds: 10);

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<List<PickupModel>> getAssignedPickups({String token = ''}) async {
    final url = '${ApiService.base}/pickups/driver';
    print('TOKEN (getAssignedPickups): $token');
    print('URL: $url');
    final res = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    ).timeout(_timeout,
        onTimeout: () => throw const SocketException('Connection timed out.'));
    print('RESPONSE (getAssignedPickups): ${res.statusCode} ${res.body}');

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => PickupModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (res.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    }
    throw Exception('Failed to load pickups');
  }

  static Future<bool> updatePickupStatus(
    String pickupId,
    String status, {
    String? notes,
    String token = '',
  }) async {
    final url = '${ApiService.base}/pickups/$pickupId/status';
    print('TOKEN (updatePickupStatus): $token');
    print('URL: $url');
    final res = await http.patch(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode({'status': status, if (notes != null) 'notes': notes}),
    ).timeout(_timeout,
        onTimeout: () => throw const SocketException('Connection timed out.'));
    print('RESPONSE (updatePickupStatus): ${res.statusCode} ${res.body}');
    return res.statusCode == 200;
  }
}
