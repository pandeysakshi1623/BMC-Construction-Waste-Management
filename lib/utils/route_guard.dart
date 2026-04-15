import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Allowed roles per route prefix. Routes not listed are public (login, signup, splash).
const _routeRoles = <String, List<String>>{
  '/contractor': ['contractor'],
  '/citizen':    ['citizen'],
  '/driver':     ['driver'],
  '/bmc':        ['bmc'],
};

/// Call this in every protected screen's [initState] or via [onGenerateRoute].
/// Returns true if access is allowed, false if the user was redirected.
bool guardRoute(BuildContext context, String routePrefix) {
  final auth = context.read<AuthProvider>();

  if (!auth.isLoggedIn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    });
    return false;
  }

  final allowed = _routeRoles[routePrefix] ?? [];
  if (allowed.isNotEmpty && !allowed.contains(auth.role)) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAccessDenied(context, auth.role);
    });
    return false;
  }

  return true;
}

void _showAccessDenied(BuildContext context, String currentRole) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Row(children: [
        Icon(Icons.lock, color: Colors.red),
        SizedBox(width: 8),
        Text('Access Denied'),
      ]),
      content: Text(
        'This section is not available for your role ($currentRole).\n'
        'Please login with the correct account.',
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (_) => false);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Go to Login',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
