import React, { useState, useCallback } from 'react'
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid, ResponsiveContainer,
  PieChart, Pie, Cell, Legend,
  LineChart, Line,
} from 'recharts'
import Spinner from '../components/ui/Spinner'
import ErrorMessage from '../components/ui/ErrorMessage'
import useFetch from '../hooks/useFetch'
import { getAnalyticsData } from '../services/api'
import { PIE_COLORS } from '../data/analyticsData'
import './Analytics.css'

const DATE_RANGES = ['Last 7 Days', 'Last 30 Days', 'Last 6 Months']

// ── Custom Tooltip ────────────────────────────────────────────────────────
function CustomTooltip({ active, payload, label, unit = 't' }) {
  if (!active || !payload?.length) return null
  return (
    <div className="custom-tooltip">
      <p className="tooltip-label">{label}</p>
      {payload.map((p, i) => (
        <p key={i} style={{ color: p.color }}>
          {p.name}: <strong>{p.value}{unit}</strong>
        </p>
      ))}
    </div>
  )
}

// ── Summary Mini Card ─────────────────────────────────────────────────────
function SummaryCard({ title, value, trend, trendUp, icon, iconBg }) {
  return (
    <div className="analytics-summary-card">
      <div className="asc-top">
        <div className="asc-icon" style={{ background: iconBg }}>{icon}</div>
        <span className={`asc-trend ${trendUp ? 'trend-up' : 'trend-down'}`}>
          {trendUp ? '▲' : '▼'} {trend}
        </span>
      </div>
      <p className="asc-title">{title}</p>
      <h3 className="asc-value">{value}</h3>
    </div>
  )
}

// ── Main Page ─────────────────────────────────────────────────────────────
export default function Analytics() {
  const [dateRange, setDateRange] = useState('Last 6 Months')

  // Wrap in useCallback so useFetch's apiFnRef stays stable when dateRange changes.
  // Changing dateRange produces a new callback reference → useFetch re-fetches.
  const fetchAnalytics = useCallback(
    () => getAnalyticsData(dateRange),
    [dateRange]
  )

  const { data: analyticsData, loading, error, retry } = useFetch(fetchAnalytics)

  if (loading) return <Spinner />
  if (error)   return <ErrorMessage message={error} onRetry={retry} />

  const chart      = analyticsData?.chart      ?? []
  const complianceData  = analyticsData?.compliance ?? []
  const analyticsSummary = analyticsData?.summary   ?? []
  const chartData = chart

  return (
    <div className="analytics-page">

      {/* Header */}
      <div className="analytics-header">
        <div>
          <h1 className="page-title">Analytics &amp; Insights</h1>
          <p className="analytics-subtitle">Mumbai BMC waste management performance overview</p>
        </div>
        <select
          className="date-filter"
          value={dateRange}
          onChange={e => setDateRange(e.target.value)}
        >
          {DATE_RANGES.map(r => <option key={r}>{r}</option>)}
        </select>
      </div>

      {/* Summary Cards */}
      <div className="analytics-summary-grid">
        {analyticsSummary.map(s => <SummaryCard key={s.id} {...s} />)}
      </div>

      {/* Charts Row 1 — Bar + Pie */}
      <div className="charts-row">

        <div className="chart-card chart-card-wide">
          <div className="chart-card-header">
            <h2 className="chart-title">Waste Collected</h2>
            <span className="chart-unit">tonnes</span>
          </div>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={chartData} margin={{ top: 8, right: 16, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
              <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} unit="t" />
              <Tooltip content={<CustomTooltip unit="t" />} />
              <Bar dataKey="waste" name="Waste" fill="#3b82f6" radius={[5, 5, 0, 0]} maxBarSize={48} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="chart-card">
          <div className="chart-card-header">
            <h2 className="chart-title">Site Compliance</h2>
            <span className="chart-unit">% share</span>
          </div>
          <ResponsiveContainer width="100%" height={260}>
            <PieChart>
              <Pie
                data={complianceData}
                cx="50%"
                cy="45%"
                innerRadius={55}
                outerRadius={90}
                dataKey="value"
                paddingAngle={3}
              >
                {complianceData.map((_, i) => (
                  <Cell key={i} fill={PIE_COLORS[i]} />
                ))}
              </Pie>
              <Tooltip formatter={(v, name) => [`${v}%`, name]} />
              <Legend
                iconType="circle"
                iconSize={8}
                formatter={v => <span style={{ fontSize: '0.78rem', color: '#64748b' }}>{v}</span>}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>

      </div>

      {/* Charts Row 2 — Line Chart */}
      <div className="chart-card chart-card-full">
        <div className="chart-card-header">
          <h2 className="chart-title">Waste Collection Trend</h2>
          <span className="chart-unit">tonnes over time</span>
        </div>
        <ResponsiveContainer width="100%" height={240}>
          <LineChart data={chartData} margin={{ top: 8, right: 24, left: 0, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
            <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
            <YAxis tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} unit="t" />
            <Tooltip content={<CustomTooltip unit="t" />} />
            <Line
              type="monotone"
              dataKey="waste"
              name="Waste"
              stroke="#3b82f6"
              strokeWidth={2.5}
              dot={{ r: 4, fill: '#3b82f6', strokeWidth: 0 }}
              activeDot={{ r: 6 }}
            />
            <Line
              type="monotone"
              dataKey="sites"
              name="Active Sites"
              stroke="#10b981"
              strokeWidth={2}
              strokeDasharray="5 4"
              dot={{ r: 3, fill: '#10b981', strokeWidth: 0 }}
            />
          </LineChart>
        </ResponsiveContainer>
        <div className="line-legend">
          <span className="legend-dot" style={{ background: '#3b82f6' }} /> Waste (t)
          <span className="legend-dot" style={{ background: '#10b981', marginLeft: 16 }} /> Active Sites
        </div>
      </div>

    </div>
  )
}
