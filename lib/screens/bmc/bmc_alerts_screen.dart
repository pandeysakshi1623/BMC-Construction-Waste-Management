import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class BmcAlertsScreen extends StatefulWidget {
  const BmcAlertsScreen({super.key});

  @override
  State<BmcAlertsScreen> createState() => _BmcAlertsScreenState();
}

class _BmcAlertsScreenState extends State<BmcAlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final data = await ApiService.getAlerts(role: 'bmc', token: token);
      setState(() => _alerts = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
             '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('BMC Alerts'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('No alerts at the moment',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _alerts.length,
                        itemBuilder: (_, i) {
                          final alert = _alerts[i];
                          final message =
                              alert['message'] as String? ?? 'No message';
                          final siteId = alert['site_id'] as String?;
                          final timestamp =
                              _formatTime(alert['timestamp'] as String?);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.red,
                                        size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(message,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14)),
                                        if (siteId != null &&
                                            siteId.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(children: [
                                            Icon(Icons.construction,
                                                size: 12,
                                                color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text('Site: $siteId',
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12)),
                                          ]),
                                        ],
                                        if (timestamp.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(children: [
                                            Icon(Icons.access_time,
                                                size: 12,
                                                color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(timestamp,
                                                style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 12)),
                                          ]),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
