import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';
import '../utils/app_theme.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? extraActions;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
    final authRole = context.watch<AuthProvider>().role;
    final role = AppRoleExt.fromString(authRole);
    final color = AppTheme.roleColor(authRole);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(title),
        actions: [
          if (extraActions != null) ...extraActions!,
          _RoleBadge(role: role, color: color),
          _LogoutButton(),
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final AppRole role;
  final Color color;
  const _RoleBadge({required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spSM + 2, vertical: AppTheme.spXS),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(role.icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(role.label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout_rounded, size: 20),
      tooltip: 'Logout',
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white),
                child: const Text('Logout'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          await context.read<AuthProvider>().logout();
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
      },
    );
  }
}
