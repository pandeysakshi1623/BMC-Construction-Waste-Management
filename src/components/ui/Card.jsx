import React from 'react'
import './Card.css'

export default function Card({ title, value, subtitle, icon, iconBg, trend, trendUp }) {
  return (
    <div className="card">
      <div className="card-top">
        <div className="card-icon-box" style={{ background: iconBg }}>
          <span className="card-icon">{icon}</span>
        </div>
        {trend && (
          <span className={`card-trend ${trendUp ? 'trend-up' : 'trend-down'}`}>
            {trendUp ? '▲' : '▼'} {trend}
          </span>
        )}
      </div>
      <p className="card-title">{title}</p>
      <h2 className="card-value">{value}</h2>
      {subtitle && <p className="card-subtitle">{subtitle}</p>}
    </div>
  )
}
