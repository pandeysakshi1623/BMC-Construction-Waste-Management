import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/role_provider.dart';
import 'providers/pickup_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/role_selection_screen.dart';
// Contractor
import 'screens/contractor/contractor_dashboard_screen.dart';
import 'screens/contractor/site_registration_screen.dart';
import 'screens/contractor/qr_display_screen.dart';
import 'screens/contractor/pickup_scheduling_screen.dart';
import 'screens/contractor/upload_proof_screen.dart';
// Citizen
import 'screens/citizen/complaints_screen.dart';
import 'screens/citizen/report_complaint_screen.dart';
import 'screens/citizen/awareness_screen.dart';
// Driver
import 'screens/driver/pickups_screen.dart';
import 'screens/driver/qr_scanner_screen.dart';
import 'screens/driver/upload_disposal_screen.dart';
// Officials / Admin
import 'screens/dashboard/analytics_dashboard_screen.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Waste Monitor',
      debugShowCheckedModeBanner: false,
      // Global notification key — no context needed to show snackbars
      scaffoldMessengerKey: NotificationService.messengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash':                     (_) => const SplashScreen(),
        '/login':                      (_) => const LoginScreen(),
        '/role-selection':             (_) => const RoleSelectionScreen(),
        // Contractor
        '/contractor/dashboard':       (_) => const ContractorDashboardScreen(),
        '/contractor/register-site':   (_) => const SiteRegistrationScreen(),
        '/contractor/qr-display':      (_) => const QrDisplayScreen(),
        '/contractor/schedule-pickup': (_) => const PickupSchedulingScreen(),
        '/contractor/upload-proof':    (_) => const UploadProofScreen(),
        // Citizen
        '/citizen/complaints':         (_) => const ComplaintsScreen(),
        '/citizen/report':             (_) => const ReportComplaintScreen(),
        '/citizen/awareness':          (_) => const AwarenessScreen(),
        // Driver
        '/driver/pickups':             (_) => const PickupsScreen(),
        '/driver/qr-scanner':          (_) => const QrScannerScreen(),
        '/driver/upload-disposal':     (_) => const UploadDisposalScreen(),
        // Officials
        '/officials/dashboard':        (_) => const AnalyticsDashboardScreen(),
      },
    );
  }
}
