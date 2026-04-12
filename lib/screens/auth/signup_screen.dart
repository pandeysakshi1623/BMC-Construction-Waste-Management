import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl  = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _nameCtrl      = TextEditingController();
  final _contactCtrl   = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _companyCtrl   = TextEditingController();
  final _addressCtrl   = TextEditingController();

  String _role = 'contractor';
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_usernameCtrl, _passwordCtrl, _nameCtrl, _contactCtrl,
                     _emailCtrl, _companyCtrl, _addressCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isContractor => _role == 'contractor';
  bool get _isBmc        => _role == 'bmc';

  Future<void> _submit() async {
    if (_isBmc || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isContractor) {
        await ApiService.signupContractor(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          contact: _contactCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          companyName: _companyCtrl.text.trim(),
        );
      } else if (_role == 'citizen') {
        await ApiService.signupCitizen(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          contact: _contactCtrl.text.trim(),
        );
      } else {
        await ApiService.signupDriver(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          contact: _contactCtrl.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Account created! Please login.'),
          backgroundColor: AppTheme.success,
        ));
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = AppTheme.roleColor(_role);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: roleColor,
        foregroundColor: Colors.white,
        title: const Text('Create Account'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role selector
                _label('Select your role'),
                AppTheme.gapSM,
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.badge_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'contractor', child: Text('Contractor')),
                    DropdownMenuItem(value: 'citizen',    child: Text('Citizen')),
                    DropdownMenuItem(value: 'driver',     child: Text('Driver')),
                    DropdownMenuItem(value: 'bmc',        child: Text('BMC Official')),
                  ],
                  onChanged: (v) { if (v != null) setState(() => _role = v); },
                ),
                AppTheme.gapMD,

                if (_isBmc) ...[
                  _InfoBanner(
                    icon: Icons.info_outline_rounded,
                    color: AppTheme.bmc,
                    message:
                        'BMC Official accounts are pre-created by the administrator.\nContact your admin for access credentials.',
                  ),
                  AppTheme.gapMD,
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Go to Login'),
                  ),
                ],

                if (!_isBmc) ...[
                  _label('Username'),
                  AppTheme.gapSM,
                  _field(_usernameCtrl, 'Enter username',
                      Icons.person_outline_rounded),
                  AppTheme.gapMD,

                  _label('Password'),
                  AppTheme.gapSM,
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Min 6 characters',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  AppTheme.gapMD,

                  _label('Full Name'),
                  AppTheme.gapSM,
                  _field(_nameCtrl, 'Enter your full name',
                      Icons.badge_outlined),
                  AppTheme.gapMD,

                  _label('Contact Number'),
                  AppTheme.gapSM,
                  _field(_contactCtrl, 'Phone or email',
                      Icons.phone_outlined,
                      type: TextInputType.phone),
                  AppTheme.gapMD,

                  if (_isContractor) ...[
                    _label('Email Address'),
                    AppTheme.gapSM,
                    _field(_emailCtrl, 'company@example.com',
                        Icons.email_outlined,
                        type: TextInputType.emailAddress,
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Enter a valid email'
                            : null),
                    AppTheme.gapMD,

                    _label('Company Name'),
                    AppTheme.gapSM,
                    _field(_companyCtrl, 'Your company name',
                        Icons.business_outlined),
                    AppTheme.gapMD,

                    _label('Address'),
                    AppTheme.gapSM,
                    _field(_addressCtrl, 'Office / site address',
                        Icons.location_on_outlined),
                    AppTheme.gapMD,
                  ],

                  AppTheme.gapSM,
                  LoadingButton(
                    isLoading: _loading,
                    label: 'Create Account',
                    color: roleColor,
                    icon: Icons.person_add_rounded,
                    onPressed: _submit,
                  ),
                ],

                AppTheme.gapMD,
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: Text('Already have an account? Login',
                      style: TextStyle(color: roleColor)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600));

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
          hintText: hint, prefixIcon: Icon(icon)),
      validator: validator ??
          (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }
}

// ignore: must_be_immutable
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.label,
    required this.onPressed,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          disabledBackgroundColor: bg.withOpacity(0.6),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: AppTheme.spSM),
                  ],
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const _InfoBanner(
      {required this.icon, required this.color, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spMD),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppTheme.spSM + 2),
        Expanded(
          child: Text(message,
              style: AppTheme.bodySmall.copyWith(color: color, height: 1.5)),
        ),
      ]),
    );
  }
}
