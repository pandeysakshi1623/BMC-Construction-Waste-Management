import 'dart:async';

class DashboardService {
  static Future<Map<String, dynamic>> getDashboardData() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'summaryCards': [
        {
          'id': 1,
          'title': 'Total Sites',
          'value': '142',
          'subtitle': 'Active sites tracking waste',
          'trend': '+12%',
          'trendUp': true,
        },
        {
          'id': 2,
          'title': 'Complaints',
          'value': '28',
          'subtitle': '3 urgent pending review',
          'trend': '-5%',
          'trendUp': false,
        },
        {
          'id': 3,
          'title': 'Waste Collected',
          'value': '4,200',
          'subtitle': 'Tons this month',
          'trend': '+8%',
          'trendUp': true,
        },
        {
          'id': 4,
          'title': 'Compliance',
          'value': '89%',
          'subtitle': 'Sites following regulations',
          'trend': '+2%',
          'trendUp': true,
        },
      ],
      'analyticsData': [
        {'month': 'Jan', 'waste': 300},
        {'month': 'Feb', 'waste': 450},
        {'month': 'Mar', 'waste': 400},
        {'month': 'Apr', 'waste': 600},
        {'month': 'May', 'waste': 700},
        {'month': 'Jun', 'waste': 850},
      ],
      'sitesData': [
        {'name': 'Site A', 'compliance': 95},
        {'name': 'Site B', 'compliance': 80},
        {'name': 'Site C', 'compliance': 88},
        {'name': 'Site D', 'compliance': 92},
      ]
    };
  }
}
