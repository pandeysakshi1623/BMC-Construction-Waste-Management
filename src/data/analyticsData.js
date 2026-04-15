// ── Bar / Line chart data ──────────────────────────────────────────────────
export const wasteByMonth = [
  { month: 'Jan', waste: 62.4, sites: 14 },
  { month: 'Feb', waste: 78.1, sites: 15 },
  { month: 'Mar', waste: 54.7, sites: 13 },
  { month: 'Apr', waste: 91.2, sites: 16 },
  { month: 'May', waste: 83.5, sites: 15 },
  { month: 'Jun', waste: 94.3, sites: 18 },
]

export const wasteLast30 = [
  { month: 'Week 1', waste: 21.4, sites: 14 },
  { month: 'Week 2', waste: 19.8, sites: 15 },
  { month: 'Week 3', waste: 24.1, sites: 16 },
  { month: 'Week 4', waste: 28.7, sites: 18 },
]

export const wasteLast7 = [
  { month: 'Mon', waste: 4.2, sites: 12 },
  { month: 'Tue', waste: 5.8, sites: 13 },
  { month: 'Wed', waste: 3.9, sites: 11 },
  { month: 'Thu', waste: 6.7, sites: 15 },
  { month: 'Fri', waste: 7.1, sites: 16 },
  { month: 'Sat', waste: 4.4, sites: 14 },
  { month: 'Sun', waste: 2.8, sites: 10 },
]

// ── Pie chart ──────────────────────────────────────────────────────────────
export const complianceData = [
  { name: 'Compliant',        value: 68 },
  { name: 'Minor Violations', value: 21 },
  { name: 'Major Violations', value: 11 },
]

export const PIE_COLORS = ['#10b981', '#f59e0b', '#ef4444']

// ── Summary cards ──────────────────────────────────────────────────────────
export const analyticsSummary = [
  { id: 1, title: 'Total Waste Collected', value: '94.3t',  trend: '+13%', trendUp: true,  icon: '♻️', iconBg: '#ecfdf5' },
  { id: 2, title: 'Active Sites',          value: '18',     trend: '+3',   trendUp: true,  icon: '🏗️', iconBg: '#eff6ff' },
  { id: 3, title: 'Violations Count',      value: '17',     trend: '-4',   trendUp: true,  icon: '⚠️', iconBg: '#fff7ed' },
]
