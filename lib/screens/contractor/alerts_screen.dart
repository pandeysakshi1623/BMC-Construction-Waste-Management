import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class AlertsScreen extends StatefulWidget {
  final String role;
  const AlertsScreen({super.key, this.role = 'contractor'});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final data = await ApiService.getAlerts(role: widget.role, token: token);
      setState(() => _alerts = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _fmt(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'];
      final hour24 = dt.hour;
      final h = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
      final ampm = hour24 >= 12 ? 'PM' : 'AM';
      return '${dt.day} ${m[dt.month-1]} ${dt.year}  '
             '${h.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} $ampm';
    } catch (_) { return raw; }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.role == 'bmc'
        ? AppTheme.bmc
        : AppTheme.contractor;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: const Text('Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : _alerts.isEmpty
                  ? _EmptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spMD),
                        itemCount: _alerts.length,
                        itemBuilder: (_, i) =>
                            _AlertTile(alert: _alerts[i], fmt: _fmt),
                      ),
                    ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final Map<String, dynamic> alert;
  final String Function(String?) fmt;
  const _AlertTile({required this.alert, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final msg = alert['message'] as String? ?? '';
    final siteId = alert['site_id'] as String? ?? '';
    final ts = fmt(alert['timestamp'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spSM + 2),
      padding: const EdgeInsets.all(AppTheme.spMD),
      decoration: AppTheme.cardDecoration,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
          child: const Icon(Icons.notifications_rounded,
              color: AppTheme.warning, size: 18),
        ),
        const SizedBox(width: AppTheme.spMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(msg, style: AppTheme.body.copyWith(fontWeight: FontWeight.w500)),
              if (siteId.isNotEmpty) ...[
                AppTheme.gapXS,
                Row(children: [
                  const Icon(Icons.construction_rounded,
                      size: 11, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Text('Site: $siteId', style: AppTheme.caption),
                ]),
              ],
              if (ts.isNotEmpty) ...[
                AppTheme.gapXS,
                Row(children: [
                  const Icon(Icons.access_time_rounded,
                      size: 11, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Text(ts, style: AppTheme.caption),
                ]),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.notifications_none_rounded,
              size: 56, color: Colors.grey[300]),
          AppTheme.gapMD,
          Text('No alerts yet', style: AppTheme.bodySmall),
        ]),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spLG),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppTheme.error),
            AppTheme.gapMD,
            Text(message,
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.error)),
            AppTheme.gapMD,
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ),
      );
}
