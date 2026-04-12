import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';

/// Drop-in replacement for Scaffold that adds:
/// - Consistent AppBar with role switcher dropdown
/// - Logout action
/// Use this in every module's home screen.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? extraActions;
  final bool showRoleSwitcher;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.extraActions,
    this.showRoleSwitcher = true,
  });

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>();
    final role = roleProvider.currentRole;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: role.color,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(title),
        actions: [
          if (extraActions != null) ...extraActions!,
          if (showRoleSwitcher) _RoleSwitcherButton(currentRole: role),
          _LogoutButton(),
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class _RoleSwitcherButton extends StatelessWidget {
  final AppRole currentRole;
  const _RoleSwitcherButton({required this.currentRole});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppRole>(
      tooltip: 'Switch Role',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(currentRole.icon, size: 18, color: Colors.white),
          const SizedBox(width: 4),
          Text(currentRole.label,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
          const Icon(Icons.arrow_drop_down, color: Colors.white),
        ],
      ),
      onSelected: (AppRole selected) async {
        if (selected == currentRole) return;
        await context.read<RoleProvider>().switchRole(selected);
        // Also sync with AuthProvider so token/prefs stay consistent
        await context.read<AuthProvider>().setRole(selected.name);
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, selected.homeRoute);
        }
      },
      itemBuilder: (_) => AppRole.values.map((role) {
        final isActive = role == currentRole;
        return PopupMenuItem<AppRole>(
          value: role,
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: role.color.withOpacity(0.15),
                child: Icon(role.icon, size: 16, color: role.color),
              ),
              const SizedBox(width: 10),
              Text(role.label,
                  style: TextStyle(
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? role.color : Colors.black87,
                  )),
              if (isActive) ...[
                const Spacer(),
                Icon(Icons.check, size: 16, color: role.color),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout',
                    style: TextStyle(color: Colors.white)),
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
