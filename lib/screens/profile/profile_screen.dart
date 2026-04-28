import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_button.dart';

/// Universal profile screen — adapts fields based on role.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _loading  = true;
  bool _saving   = false;
  bool _editing  = false;
  Map<String, dynamic>? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _companyCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String get _role => context.read<AuthProvider>().role;
  String get _token => context.read<AuthProvider>().user?.token ?? '';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    // BMC officials don't have a profile endpoint — show stub immediately
    if (_role == 'bmc') {
      setState(() {
        _profile = {'name': 'BMC Official', 'contact': '', 'email': 'admin@bmc.gov'};
        _loading = false;
      });
      _fillControllers(_profile!);
      return;
    }
    try {
      print('TOKEN (profile load): $_token');
      final data = await ApiService.getProfile(role: _role, token: _token);
      _fillControllers(data);
      setState(() => _profile = data);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('Session expired') || msg.contains('401')) {
        await context.read<AuthProvider>().handleUnauthorized();
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        return;
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillControllers(Map<String, dynamic> data) {
    _nameCtrl.text    = data['name']         ?? '';
    _contactCtrl.text = data['contact']      ?? '';
    _emailCtrl.text   = data['email']        ?? '';
    _companyCtrl.text = data['company_name'] ?? '';
    _addressCtrl.text = data['address']      ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await ApiService.updateProfile(
        role: _role,
        token: _token,
        name:        _nameCtrl.text.trim(),
        contact:     _contactCtrl.text.trim(),
        email:       _emailCtrl.text.trim(),
        companyName: _companyCtrl.text.trim(),
        address:     _addressCtrl.text.trim(),
      );
      _fillControllers(updated);
      setState(() { _profile = updated; _editing = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_rounded, color: AppTheme.error),
          SizedBox(width: 8),
          Text('Delete Account'),
        ]),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.deleteProfile(role: _role, token: _token);
      if (mounted) {
        await context.read<AuthProvider>().logout();
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  Color get _roleColor => AppTheme.roleColor(_role);

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: _roleColor,
        foregroundColor: Colors.white,
        title: const Text('My Profile'),
        actions: [
          // BMC profile is read-only — no edit button
          if (_role != 'bmc' && !_loading && _error == null)
            IconButton(
              icon: Icon(_editing ? Icons.close_rounded : Icons.edit_rounded),
              tooltip: _editing ? 'Cancel' : 'Edit',
              onPressed: () => setState(() => _editing = !_editing),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spLG),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Avatar + role badge
                        Center(
                          child: Column(children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: _roleColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _roleColor.withOpacity(0.3),
                                    width: 2),
                              ),
                              child: Icon(_roleIcon, color: _roleColor, size: 36),
                            ),
                            AppTheme.gapSM,
                            Text(auth.user?.email ?? '',
                                style: AppTheme.heading3),
                            AppTheme.gapXS,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _roleColor.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusFull),
                                border: Border.all(
                                    color: _roleColor.withOpacity(0.3)),
                              ),
                              child: Text(_roleLabel,
                                  style: TextStyle(
                                      color: _roleColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ),
                          ]),
                        ),
                        AppTheme.gapLG,

                        // Fields
                        _field('Full Name', _nameCtrl, Icons.person_outline_rounded),
                        AppTheme.gapMD,
                        _field('Contact / Phone', _contactCtrl, Icons.phone_outlined,
                            type: TextInputType.phone),
                        AppTheme.gapMD,

                        if (_role == 'contractor' || _role == 'citizen') ...[
                          _field('Email', _emailCtrl, Icons.email_outlined,
                              type: TextInputType.emailAddress),
                          AppTheme.gapMD,
                        ],

                        if (_role == 'contractor') ...[
                          _field('Company Name', _companyCtrl,
                              Icons.business_outlined),
                          AppTheme.gapMD,
                          _field('Address', _addressCtrl,
                              Icons.location_on_outlined),
                          AppTheme.gapMD,
                        ],

                        if (_editing) ...[
                          AppTheme.gapSM,
                          LoadingButton(
                            isLoading: _saving,
                            label: 'Save Changes',
                            color: _roleColor,
                            icon: Icons.save_rounded,
                            onPressed: _save,
                          ),
                          AppTheme.gapMD,
                        ],

                        // Danger zone — hidden for BMC
                        if (_role != 'bmc') ...[
                          const Divider(),
                          AppTheme.gapMD,
                          Text('Danger Zone',
                              style: AppTheme.caption.copyWith(
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.w600)),
                          AppTheme.gapSM,
                          OutlinedButton.icon(
                            onPressed: _deleteAccount,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: const BorderSide(color: AppTheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.delete_forever_rounded),
                            label: const Text('Delete My Account'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      enabled: _editing,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: _editing ? AppTheme.surface : AppTheme.bg,
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }

  IconData get _roleIcon {
    switch (_role) {
      case 'contractor': return Icons.engineering_rounded;
      case 'citizen':    return Icons.person_rounded;
      case 'driver':     return Icons.local_shipping_rounded;
      case 'bmc':        return Icons.account_balance_rounded;
      default:           return Icons.person_rounded;
    }
  }

  String get _roleLabel {
    switch (_role) {
      case 'contractor': return 'Contractor';
      case 'citizen':    return 'Citizen';
      case 'driver':     return 'Driver';
      case 'bmc':        return 'BMC Official';
      default:           return _role;
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}
