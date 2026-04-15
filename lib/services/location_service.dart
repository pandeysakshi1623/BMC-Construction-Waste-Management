import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? error;

  bool get success => latitude != null && longitude != null;

  const LocationResult({this.latitude, this.longitude, this.error});
}

class LocationService {
  /// Requests permission and returns current position or an error message.
  static Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
            error: 'Location services are disabled. Please enable GPS.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(error: 'Location permission denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
            error:
                'Location permission permanently denied. Please enable it in app settings.');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationResult(latitude: pos.latitude, longitude: pos.longitude);
    } catch (e) {
      return LocationResult(error: 'Failed to get location: $e');
    }
  }

  /// Formats lat/lng as a readable string
  static String format(double lat, double lng) {
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  /// Converts lat/lng to a human-readable address.
  /// Falls back to formatted coordinates if geocoding fails.
  static Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return format(lat, lng);

      final p = placemarks.first;

      // Build address from most specific to least specific
      final parts = [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.country,
      ].where((s) => s != null && s.isNotEmpty).toList();

      if (parts.isEmpty) return format(lat, lng);

      // Return up to 3 most relevant parts for a clean display
      return parts.take(3).join(', ');
    } catch (_) {
      return format(lat, lng);
    }
  }
}
