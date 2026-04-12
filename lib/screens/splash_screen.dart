import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Wait for auth provider to restore session from prefs
    final auth = context.read<AuthProvider>();

    // Poll until initialized (usually instant)
    while (!auth.initialized) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Small delay so splash is visible
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    if (auth.isLoggedIn) {
      switch (auth.user!.role) {
        case 'contractor':
          Navigator.pushReplacementNamed(context, '/contractor/dashboard');
          break;
        case 'citizen':
          Navigator.pushReplacementNamed(context, '/citizen/complaints');
          break;
        case 'driver':
          Navigator.pushReplacementNamed(context, '/driver/pickups');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Smart Waste Monitor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Construction Waste Management',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
