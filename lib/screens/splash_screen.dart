import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';

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
    final auth = context.read<AuthProvider>();
    while (!auth.initialized) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;

    if (auth.isLoggedIn) {
      // Sync RoleProvider so the badge shows the correct role immediately
      context.read<RoleProvider>().syncFromAuthRole(auth.role);
      switch (auth.role) {
        case 'contractor':
          Navigator.pushReplacementNamed(context, '/contractor/dashboard'); break;
        case 'driver':
          Navigator.pushReplacementNamed(context, '/driver/pickups'); break;
        case 'citizen':
          Navigator.pushReplacementNamed(context, '/citizen/complaints'); break;
        case 'bmc':
          Navigator.pushReplacementNamed(context, '/bmc/dashboard'); break;
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
      backgroundColor: const Color(0xFF1A237E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_sweep_rounded,
                  size: 72, color: Colors.white),
            ),
            const SizedBox(height: 28),
            const Text('Smart Waste Monitor',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text('BMC Construction Waste Management',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 13)),
            const SizedBox(height: 56),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
