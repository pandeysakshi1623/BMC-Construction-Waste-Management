import 'package:flutter/material.dart';

class AwarenessScreen extends StatelessWidget {
  const AwarenessScreen({super.key});

  static const _tips = [
    _TipData(
      icon: Icons.recycling,
      color: Color(0xFF2E7D32),
      title: 'Segregate Your Waste',
      body:
          'Separate waste into organic, recyclable, and hazardous categories before disposal. This makes recycling easier and reduces landfill load.',
    ),
    _TipData(
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFF1565C0),
      title: 'Reduce Single-Use Items',
      body:
          'Avoid single-use plastics. Carry reusable bags, bottles, and containers. Small changes add up to a big environmental impact.',
    ),
    _TipData(
      icon: Icons.construction,
      color: Color(0xFFE65100),
      title: 'Construction Waste Tips',
      body:
          'Plan material quantities carefully to avoid excess. Reuse offcuts where possible. Store materials properly to prevent weather damage and waste.',
    ),
    _TipData(
      icon: Icons.compost,
      color: Color(0xFF558B2F),
      title: 'Composting Organic Waste',
      body:
          'Food scraps and garden waste can be composted into rich fertilizer. This diverts waste from landfills and enriches soil naturally.',
    ),
    _TipData(
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFC62828),
      title: 'Hazardous Waste Disposal',
      body:
          'Never dump chemicals, batteries, or paint down drains. Use designated hazardous waste collection points to protect water and soil.',
    ),
    _TipData(
      icon: Icons.water_drop_outlined,
      color: Color(0xFF0277BD),
      title: 'Protect Water Sources',
      body:
          'Construction runoff can contaminate groundwater. Use silt fences and proper drainage to keep waste away from water sources.',
    ),
    _TipData(
      icon: Icons.lightbulb_outline,
      color: Color(0xFFF9A825),
      title: 'Report Illegal Dumping',
      body:
          'If you see illegal waste dumping, report it immediately using the app. Your report helps keep the community clean and safe.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Waste Awareness'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Every Action Counts',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text(
                        'Learn how to manage waste responsibly and protect your community.',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.eco, size: 56, color: Colors.white70),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Tips & Guidelines',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._tips.map((tip) => _TipCard(tip: tip)),
          const SizedBox(height: 8),
          // Recycling guide
          _RecyclingGuide(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final _TipData tip;
  const _TipCard({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tip.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tip.icon, color: tip.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(tip.body,
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecyclingGuide extends StatelessWidget {
  final _categories = const [
    _RecycleItem(Icons.delete, Colors.green, 'Organic', 'Food, garden waste'),
    _RecycleItem(Icons.inventory_2_outlined, Colors.blue, 'Paper', 'Cardboard, newspapers'),
    _RecycleItem(Icons.local_drink_outlined, Colors.teal, 'Plastic', 'Bottles, containers'),
    _RecycleItem(Icons.hardware, Colors.orange, 'Metal', 'Cans, scrap metal'),
    _RecycleItem(Icons.dangerous_outlined, Colors.red, 'Hazardous', 'Chemicals, batteries'),
  ];

  const _RecyclingGuide();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Waste Segregation Guide',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories
                  .map((c) => _RecycleBadge(item: c))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecycleBadge extends StatelessWidget {
  final _RecycleItem item;
  const _RecycleBadge({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 14, color: item.color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label,
                  style: TextStyle(
                      color: item.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              Text(item.sub,
                  style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────
class _TipData {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _TipData(
      {required this.icon,
      required this.color,
      required this.title,
      required this.body});
}

class _RecycleItem {
  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  const _RecycleItem(this.icon, this.color, this.label, this.sub);
}
