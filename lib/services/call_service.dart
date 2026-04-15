import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CallService {
  /// Launches the phone dialer with the given number.
  static Future<void> call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot call $phone'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
