import React from 'react'
import Card from '../components/ui/Card'
import Spinner from '../components/ui/Spinner'
import ErrorMessage from '../components/ui/ErrorMessage'
import useFetch from '../hooks/useFetch'
import { getDashboardData } from '../services/api'
import './Dashboard.css'

export default function Dashboard() {
  const { data: cards, loading, error, retry } = useFetch(getDashboardData)

  if (loading) return <Spinner />
  if (error)   return <ErrorMessage message={error} onRetry={retry} />

  return (
    <div className="dashboard">
      <div className="dashboard-header">
        <h1 className="dashboard-title">Dashboard Overview</h1>
        <p className="dashboard-subtitle">Welcome back — here's what's happening today.</p>
      </div>

      <section>
        <h2 className="section-label">Summary</h2>
        <div className="summary-grid">
          {cards.map(({ id, title, value, subtitle, icon, iconBg, trend, trendUp }) => (
            <Card
              key={id}
              title={title}
              value={value}
              subtitle={subtitle}
              icon={icon}
              iconBg={iconBg}
              trend={trend}
              trendUp={trendUp}
            />
          ))}
        </div>
      </section>
    </div>
  )
}
