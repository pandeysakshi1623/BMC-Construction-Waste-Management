import React from 'react'
import { NavLink } from 'react-router-dom'
import './Sidebar.css'

const navItems = [
  { to: '/dashboard',  label: 'Dashboard',  icon: '📊' },
  { to: '/sites',      label: 'Sites',       icon: '🏗️' },
  { to: '/complaints', label: 'Complaints',  icon: '⚠️' },
  { to: '/analytics',  label: 'Analytics',   icon: '📈' },
]

export default function Sidebar() {
  return (
    <aside className="sidebar">

      {/* Branding */}
      <div className="sidebar-brand">
        <span className="sidebar-brand-name">EcoTrack BMC</span>
        <span className="sidebar-brand-sub">Waste Monitoring System</span>
      </div>

      {/* Navigation */}
      <nav className="sidebar-nav">
        {navItems.map(({ to, label, icon }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) =>
              'sidebar-link' + (isActive ? ' active' : '')
            }
          >
            <span className="sidebar-link-icon">{icon}</span>
            <span>{label}</span>
          </NavLink>
        ))}
      </nav>

      {/* User Profile */}
      <div className="sidebar-profile">
        <div className="sidebar-avatar">AK</div>
        <div className="sidebar-profile-info">
          <span className="sidebar-profile-name">Admin Kumar</span>
          <span className="sidebar-profile-role">BMC Officer</span>
        </div>
      </div>

    </aside>
  )
}
