import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/role_provider.dart';
import 'providers/pickup_provider.dart';
import 'utils/app_theme.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/role_selection_screen.dart';
// Contractor
import 'screens/contractor/contractor_dashboard_screen.dart';
import 'screens/contractor/site_registration_screen.dart';
import 'screens/contractor/alerts_screen.dart';
import 'screens/contractor/qr_display_screen.dart';
import 'screens/contractor/pickup_scheduling_screen.dart';
import 'screens/contractor/upload_proof_screen.dart';
// Citizen
import 'screens/citizen/complaints_screen.dart';
import 'screens/citizen/awareness_screen.dart';
// Driver
import 'screens/driver/pickups_screen.dart';
import 'screens/driver/qr_scanner_screen.dart';
import 'screens/driver/upload_disposal_screen.dart';
// BMC
import 'screens/bmc/bmc_dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => PickupProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Routes that don't require authentication
const _publicRoutes = {'/splash', '/login', '/signup', '/role-selection'};

/// Allowed role per route prefix
const _routeRoles = <String, String>{
  '/contractor': 'contractor',
  '/citizen':    'citizen',
  '/driver':     'driver',
  '/bmc':        'bmc',
};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Waste Monitor',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: NotificationService.messengerKey,
      theme: AppTheme.theme,
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/splash';

        // Public routes — no auth needed
        if (_publicRoutes.contains(name)) {
          return _buildRoute(settings);
        }

        // Protected routes — check auth + role
        final auth = context.read<AuthProvider>();

        if (!auth.isLoggedIn) {
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
            settings: const RouteSettings(name: '/login'),
          );
        }

        // Find which role prefix this route belongs to
        final requiredRole = _routeRoles.entries
            .where((e) => name.startsWith(e.key))
            .map((e) => e.value)
            .firstOrNull;

        if (requiredRole != null && auth.role != requiredRole) {
          // Wrong role — show access denied and stay on current screen
          return MaterialPageRoute(
            builder: (_) => _AccessDeniedScreen(
              attemptedRole: requiredRole,
              currentRole: auth.role,
            ),
          );
        }

        return _buildRoute(settings);
      },
    );
  }

  Route<dynamic> _buildRoute(RouteSettings settings) {
    final builder = _routes[settings.name];
    if (builder == null) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
    return MaterialPageRoute(builder: builder, settings: settings);
  }

  static final _routes = <String, WidgetBuilder>{
    '/splash':                     (_) => const SplashScreen(),
    '/login':                      (_) => const LoginScreen(),
    '/signup':                     (_) => const SignupScreen(),
    '/role-selection':             (_) => const RoleSelectionScreen(),
    // Contractor
    '/contractor/dashboard':       (_) => const ContractorDashboardScreen(),
    '/contractor/register-site':   (_) => const SiteRegistrationScreen(),
    '/contractor/alerts':          (_) => const AlertsScreen(role: 'contractor'),
    '/contractor/qr-display':      (_) => const QrDisplayScreen(),
    '/contractor/schedule-pickup': (_) => const PickupSchedulingScreen(),
    '/contractor/upload-proof':    (_) => const UploadProofScreen(),
    // Citizen
    '/citizen/complaints':         (_) => const ComplaintsScreen(),
    '/citizen/awareness':          (_) => const AwarenessScreen(),
    // Driver
    '/driver/pickups':             (_) => const PickupsScreen(),
    '/driver/qr-scanner':          (_) => const QrScannerScreen(),
    '/driver/upload-disposal':     (_) => const UploadDisposalScreen(),
    // BMC
    '/bmc/dashboard':              (_) => const BmcDashboardScreen(),
  };
}

/// Shown when a user tries to access a route outside their role
class _AccessDeniedScreen extends StatelessWidget {
  final String attemptedRole;
  final String currentRole;

  const _AccessDeniedScreen({
    required this.attemptedRole,
    required this.currentRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 72, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Access Denied',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'This section requires a $attemptedRole account.\n'
                'You are logged in as: $currentRole.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (_) => false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Login with correct account'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
