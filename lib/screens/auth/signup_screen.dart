import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common fields
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();

  // Contractor-only fields
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedRole = 'contractor';
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _isContractor => _selectedRole == 'contractor';
  bool get _isCitizen => _selectedRole == 'citizen';
  bool get _isDriver => _selectedRole == 'driver';
  bool get _isBmc => _selectedRole == 'bmc';

  Future<void> _handleSignup() async {
    // BMC cannot self-register
    if (_isBmc) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      if (_isContractor) {
        await ApiService.signupContractor(
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          contact: _contactController.text.trim(),
          address: _addressController.text.trim(),
          email: _emailController.text.trim(),
          companyName: _companyController.text.trim(),
        );
      } else if (_isCitizen) {
        await ApiService.signupCitizen(
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          contact: _contactController.text.trim(),
        );
      } else if (_isDriver) {
        await ApiService.signupDriver(
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          contact: _contactController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.construction, size: 56, color: Colors.orange),
                const SizedBox(height: 12),
                const Text(
                  'Smart Waste Monitor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Register a new account',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 28),

                // Role dropdown — shown first so fields update accordingly
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'contractor', child: Text('Contractor')),
                    DropdownMenuItem(
                        value: 'citizen', child: Text('Citizen')),
                    DropdownMenuItem(
                        value: 'driver', child: Text('Driver')),
                    DropdownMenuItem(
                        value: 'bmc', child: Text('BMC Official')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: 14),

                // BMC info message — no self-registration
                if (_isBmc) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF1A237E).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFF1A237E), size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'BMC Official accounts are pre-created by the admin.\nPlease contact your administrator for access.',
                            style: TextStyle(
                                color: Color(0xFF1A237E),
                                fontSize: 13,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Go to Login'),
                  ),
                ],

                // Form fields — hidden for BMC
                if (!_isBmc) ...[
                // Username — all roles
                _field(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),

                // Password — all roles
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 14),

                // Full name — all roles
                _field(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 14),

                // Contact — all roles
                _field(
                  controller: _contactController,
                  label: 'Contact Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                // Contractor-only fields
                if (_isContractor) ...[
                  const SizedBox(height: 14),
                  _field(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _companyController,
                    label: 'Company Name',
                    icon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on_outlined,
                  ),
                ],

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _loading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Sign Up',
                          style: TextStyle(fontSize: 16)),
                ),
                ], // end !_isBmc

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator ??
          (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }
}
