import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/site_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_button.dart';

class SiteRegistrationScreen extends StatefulWidget {
  const SiteRegistrationScreen({super.key});
  @override
  State<SiteRegistrationScreen> createState() => _SiteRegistrationScreenState();
}

class _SiteRegistrationScreenState extends State<SiteRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _areaCtrl     = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _locationCtrl.dispose(); _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final data = await ApiService.registerSite(
        name: _nameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        token: token,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/contractor/qr-display',
            arguments: SiteModel.fromJson(data));
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
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.contractor,
        foregroundColor: Colors.white,
        title: const Text('Register Site'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spLG),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(AppTheme.spMD),
                decoration: BoxDecoration(
                  color: AppTheme.contractor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.contractor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_business_rounded,
                        color: AppTheme.contractor, size: 22),
                  ),
                  const SizedBox(width: AppTheme.spMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Construction Site',
                            style: AppTheme.heading3),
                        AppTheme.gapXS,
                        Text('Fill in the details to register and get a QR code',
                            style: AppTheme.caption),
                      ],
                    ),
                  ),
                ]),
              ),
              AppTheme.gapLG,

              _field(_nameCtrl, 'Site Name', 'e.g. Tower Block A',
                  Icons.business_rounded),
              AppTheme.gapMD,
              _field(_locationCtrl, 'Location / Address',
                  'e.g. Main St, Block 5', Icons.location_on_rounded),
              AppTheme.gapMD,
              _field(_areaCtrl, 'Plot Area (m²)', 'e.g. 500',
                  Icons.square_foot_rounded,
                  type: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v.trim()) == null) {
                      return 'Enter a whole number';
                    }
                    return null;
                  }),
              AppTheme.gapXL,

              LoadingButton(
                isLoading: _loading,
                label: 'Register & Generate QR',
                color: AppTheme.contractor,
                icon: Icons.qr_code_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: validator ??
          (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }
}
