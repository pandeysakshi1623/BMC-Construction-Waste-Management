import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/site_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_button.dart';

class PickupSchedulingScreen extends StatefulWidget {
  const PickupSchedulingScreen({super.key});
  @override
  State<PickupSchedulingScreen> createState() => _PickupSchedulingScreenState();
}

class _PickupSchedulingScreenState extends State<PickupSchedulingScreen> {
  DateTime? _date;
  bool _loading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppTheme.contractor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit(SiteModel site) async {
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a pickup date'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }
    setState(() => _loading = true);
    final dateStr =
        '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      await ApiService.schedulePickup(site.id, dateStr, token: token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Pickup scheduled for $dateStr'),
          backgroundColor: AppTheme.success,
        ));
        Navigator.pop(context);
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
    final site = ModalRoute.of(context)!.settings.arguments as SiteModel;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.contractor,
        foregroundColor: Colors.white,
        title: const Text('Schedule Pickup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Site card
            Container(
              padding: const EdgeInsets.all(AppTheme.spMD),
              decoration: AppTheme.cardDecoration,
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.contractor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.business_rounded,
                      color: AppTheme.contractor, size: 20),
                ),
                const SizedBox(width: AppTheme.spMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(site.name, style: AppTheme.heading3),
                      AppTheme.gapXS,
                      Text(site.location, style: AppTheme.caption),
                    ],
                  ),
                ),
              ]),
            ),
            AppTheme.gapLG,

            Text('Select Pickup Date', style: AppTheme.heading3),
            AppTheme.gapSM,
            Text('Choose a date within the next 60 days',
                style: AppTheme.caption),
            AppTheme.gapMD,

            // Date picker tile
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spMD),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(
                    color: _date != null
                        ? AppTheme.contractor
                        : AppTheme.divider,
                    width: _date != null ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_month_rounded,
                      color: _date != null
                          ? AppTheme.contractor
                          : AppTheme.textHint,
                      size: 22),
                  const SizedBox(width: AppTheme.spMD),
                  Expanded(
                    child: Text(
                      _date == null
                          ? 'Tap to select a date'
                          : '${_date!.day} / ${_date!.month} / ${_date!.year}',
                      style: AppTheme.body.copyWith(
                        color: _date == null
                            ? AppTheme.textHint
                            : AppTheme.textPrimary,
                        fontWeight: _date != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textHint, size: 20),
                ]),
              ),
            ),

            const Spacer(),
            LoadingButton(
              isLoading: _loading,
              label: 'Confirm Schedule',
              color: AppTheme.contractor,
              icon: Icons.check_rounded,
              onPressed: () => _submit(site),
            ),
          ],
        ),
      ),
    );
  }
}
