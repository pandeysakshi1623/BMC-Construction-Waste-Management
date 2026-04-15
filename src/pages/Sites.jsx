import React, { useState, useMemo } from 'react'
import Spinner from '../components/ui/Spinner'
import ErrorMessage from '../components/ui/ErrorMessage'
import useFetch from '../hooks/useFetch'
import { getSites } from '../services/api'
import './Sites.css'

export default function Sites() {
  // ── All hooks at the top — never after a conditional return ──
  const { data, loading, error, retry } = useFetch(getSites)
  const [query, setQuery]   = useState('')
  const [filter, setFilter] = useState('All')

  const allSites = useMemo(() => data ?? [], [data])

  const activeCount   = useMemo(() => allSites.filter(s => s.status === 'Active').length,   [allSites])
  const inactiveCount = useMemo(() => allSites.filter(s => s.status === 'Inactive').length, [allSites])

  const filtered = useMemo(() => allSites.filter(s => {
    const matchesSearch =
      s.name.toLowerCase().includes(query.toLowerCase()) ||
      s.location.toLowerCase().includes(query.toLowerCase()) ||
      s.id.toLowerCase().includes(query.toLowerCase())
    const matchesFilter = filter === 'All' || s.status === filter
    return matchesSearch && matchesFilter
  }), [allSites, query, filter])

  // ── Early returns after all hooks ──
  if (loading) return <Spinner />
  if (error)   return <ErrorMessage message={error} onRetry={retry} />

  return (
    <div className="sites-page">

      {/* Header */}
      <div className="sites-header">
        <div>
          <h1 className="page-title">Sites</h1>
          <p className="sites-subtitle">Waste collection sites across Mumbai</p>
        </div>
      </div>

      {/* Stat pills */}
      <div className="sites-stats">
        <div className="stat-pill">
          <span className="stat-dot dot-all" />
          <span className="stat-label">Total</span>
          <span className="stat-value">{allSites.length}</span>
        </div>
        <div className="stat-pill">
          <span className="stat-dot dot-active" />
          <span className="stat-label">Active</span>
          <span className="stat-value">{activeCount}</span>
        </div>
        <div className="stat-pill">
          <span className="stat-dot dot-inactive" />
          <span className="stat-label">Inactive</span>
          <span className="stat-value">{inactiveCount}</span>
        </div>
      </div>

      {/* Controls */}
      <div className="sites-controls">
        <div className="search-wrapper">
          <span className="search-icon">🔍</span>
          <input
            className="search-input"
            type="text"
            placeholder="Search by name, location or ID..."
            value={query}
            onChange={e => setQuery(e.target.value)}
          />
          {query && (
            <button className="search-clear" onClick={() => setQuery('')}>✕</button>
          )}
        </div>
        <select
          className="filter-select"
          value={filter}
          onChange={e => setFilter(e.target.value)}
        >
          <option value="All">All Status</option>
          <option value="Active">Active</option>
          <option value="Inactive">Inactive</option>
        </select>
      </div>

      {/* Table */}
      <div className="table-container">
        <div className="table-scroll">
          <table className="sites-table">
            <thead>
              <tr>
                <th>Site ID</th>
                <th>Site Name</th>
                <th>Location</th>
                <th>Status</th>
                <th>Waste Collected</th>
                <th>Last Updated</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length > 0 ? (
                filtered.map((site, index) => (
                  <tr key={site.id} className={index % 2 === 0 ? 'row-even' : 'row-odd'}>
                    <td><span className="site-id">{site.id}</span></td>
                    <td><span className="site-name">{site.name}</span></td>
                    <td>{site.location}</td>
                    <td>
                      <span className={`badge badge-${site.status.toLowerCase()}`}>
                        {site.status}
                      </span>
                    </td>
                    <td><span className="waste-value">{site.waste}</span></td>
                    <td><span className="date-value">{site.lastUpdated}</span></td>
                    <td>
                      <div className="action-buttons">
                        <button className="btn btn-view">View</button>
                        <button className="btn btn-delete">Delete</button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="7">
                    <div className="empty-state">
                      <span className="empty-icon">🏗️</span>
                      <p>No sites found</p>
                      <span>Try adjusting your search or filter</span>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <p className="results-count">
        Showing {filtered.length} of {allSites.length} sites
      </p>

    </div>
  )
}
