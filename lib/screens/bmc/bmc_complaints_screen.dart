import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class BmcComplaintsScreen extends StatefulWidget {
  const BmcComplaintsScreen({super.key});

  @override
  State<BmcComplaintsScreen> createState() => _BmcComplaintsScreenState();
}

class _BmcComplaintsScreenState extends State<BmcComplaintsScreen> {
  List<Map<String, dynamic>> _complaints = [];
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
      final data = await ApiService.getBmcComplaints(token: token);
      setState(() => _complaints = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'resolved': return Colors.green;
      case 'underreview': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Citizen Complaints'),
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
              : _complaints.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.report_off,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('No complaints found',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _complaints.length,
                        itemBuilder: (_, i) {
                          final c = _complaints[i];
                          final status = c['status'] ?? 'Pending';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          c['description'] ??
                                              'No description',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: _statusColor(status)
                                                  .withOpacity(0.4)),
                                        ),
                                        child: Text(status,
                                            style: TextStyle(
                                                color: _statusColor(status),
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (c['site_id'] != null)
                                    _infoRow(Icons.construction,
                                        'Site: ${c['site_id']}'),
                                  if (c['citizen_id'] != null)
                                    _infoRow(Icons.person_outline,
                                        'Citizen: ${c['citizen_id']}'),
                                  if (c['created_at'] != null)
                                    _infoRow(Icons.calendar_today,
                                        c['created_at']),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(icon, size: 13, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ),
          ],
        ),
      );
}
