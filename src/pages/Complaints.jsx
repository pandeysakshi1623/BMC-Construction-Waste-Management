import React, { useState, useEffect, useMemo } from 'react'
import Spinner from '../components/ui/Spinner'
import ErrorMessage from '../components/ui/ErrorMessage'
import useFetch from '../hooks/useFetch'
import { getComplaints } from '../services/api'
import './Complaints.css'

const BANNER_COLORS = {
  'Overflow':        '#fef3c7',
  'Illegal Dumping': '#fee2e2',
  'Missed Pickup':   '#e0f2fe',
  'Burning':         '#ffedd5',
  'Drainage':        '#ede9fe',
  'Odour':           '#fce7f3',
  'Medical Waste':   '#dcfce7',
  'Segregation':     '#f1f5f9',
}

const BANNER_ICON = {
  'Overflow':        '🗑️',
  'Illegal Dumping': '🚫',
  'Missed Pickup':   '🚛',
  'Burning':         '🔥',
  'Drainage':        '💧',
  'Odour':           '💨',
  'Medical Waste':   '🏥',
  'Segregation':     '♻️',
}

const FILTERS = ['All', 'Pending', 'Resolved']

export default function Complaints() {
  // ── All hooks at the top — never after a conditional return ──
  const { data, loading, error, retry } = useFetch(getComplaints)
  const [complaints, setComplaints] = useState([])
  const [activeFilter, setActiveFilter] = useState('All')
  const [query, setQuery]               = useState('')
  const [modal, setModal]               = useState(null)

  // Seed local state once API data arrives so markResolved can mutate it
  useEffect(() => {
    if (data) setComplaints(data)
  }, [data])

  const filtered = useMemo(() => complaints.filter(c => {
    const matchFilter = activeFilter === 'All' || c.status === activeFilter
    const matchSearch =
      c.location.toLowerCase().includes(query.toLowerCase()) ||
      c.id.toLowerCase().includes(query.toLowerCase())
    return matchFilter && matchSearch
  }), [complaints, activeFilter, query])

  const pendingCount  = useMemo(() => complaints.filter(c => c.status === 'Pending').length,  [complaints])
  const resolvedCount = useMemo(() => complaints.filter(c => c.status === 'Resolved').length, [complaints])

  // ── Early returns after all hooks ──
  if (loading) return <Spinner />
  if (error)   return <ErrorMessage message={error} onRetry={retry} />

  function markResolved(id) {
    setComplaints(prev =>
      prev.map(c => c.id === id ? { ...c, status: 'Resolved' } : c)
    )
    setModal(prev => prev?.id === id ? { ...prev, status: 'Resolved' } : prev)
  }

  return (
    <div className="complaints-page">

      {/* Page Header */}
      <div className="complaints-header">
        <div>
          <h1 className="page-title">Complaints Management</h1>
          <p className="complaints-subtitle">
            {pendingCount} pending &nbsp;·&nbsp; {resolvedCount} resolved &nbsp;·&nbsp; {complaints.length} total
          </p>
        </div>
      </div>

      {/* Search + Filters */}
      <div className="complaints-controls">
        <div className="search-wrapper">
          <span className="search-icon">🔍</span>
          <input
            className="search-input"
            type="text"
            placeholder="Search by location or ID..."
            value={query}
            onChange={e => setQuery(e.target.value)}
          />
        </div>
        <div className="filter-tabs">
          {FILTERS.map(f => (
            <button
              key={f}
              className={`filter-tab ${activeFilter === f ? 'filter-tab-active' : ''}`}
              onClick={() => setActiveFilter(f)}
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      {/* Grid */}
      {filtered.length > 0 ? (
        <div className="complaints-grid">
          {filtered.map(complaint => {
            const { id, location, description, status, timestamp, category } = complaint
            const isPending = status === 'Pending'
            return (
              <div key={id} className="complaint-card">

                <div
                  className="card-banner"
                  style={{ background: BANNER_COLORS[category] || '#f1f5f9' }}
                >
                  <span className="banner-icon">{BANNER_ICON[category] || '📋'}</span>
                  <span className="banner-category">{category}</span>
                </div>

                <div className="card-body">
                  <div className="card-top-row">
                    <span className="complaint-id">{id}</span>
                    <span className={`badge badge-${status.toLowerCase()}`}>{status}</span>
                  </div>
                  <p className="complaint-location">📍 {location}</p>
                  <p className="complaint-description">{description}</p>
                  <p className="complaint-timestamp">🕐 {timestamp}</p>
                </div>

                <div className="card-footer">
                  <button className="btn-view-details" onClick={() => setModal(complaint)}>
                    View Details
                  </button>
                  {isPending && (
                    <button className="btn-resolve" onClick={() => markResolved(id)}>
                      Mark Resolved
                    </button>
                  )}
                </div>

              </div>
            )
          })}
        </div>
      ) : (
        <div className="empty-state">
          <span className="empty-icon">📋</span>
          <p>No complaints found</p>
          <span>Try adjusting your search or filter</span>
        </div>
      )}

      {/* Modal */}
      {modal && (
        <div className="modal-overlay" onClick={() => setModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div
              className="modal-banner"
              style={{ background: BANNER_COLORS[modal.category] || '#f1f5f9' }}
            >
              <span className="banner-icon">{BANNER_ICON[modal.category] || '📋'}</span>
              <button className="modal-close" onClick={() => setModal(null)}>✕</button>
            </div>
            <div className="modal-body">
              <div className="modal-id-row">
                <span className="complaint-id">{modal.id}</span>
                <span className={`badge badge-${modal.status.toLowerCase()}`}>{modal.status}</span>
              </div>
              <h2 className="modal-location">{modal.location}</h2>
              <p className="modal-category">{modal.category}</p>
              <p className="modal-description">{modal.description}</p>
              <div className="modal-meta">
                <div className="modal-meta-item">
                  <span className="meta-label">Reported By</span>
                  <span className="meta-value">{modal.reportedBy}</span>
                </div>
                <div className="modal-meta-item">
                  <span className="meta-label">Timestamp</span>
                  <span className="meta-value">{modal.timestamp}</span>
                </div>
              </div>
              {modal.status === 'Pending' && (
                <button
                  className="btn-resolve modal-resolve-btn"
                  onClick={() => markResolved(modal.id)}
                >
                  Mark as Resolved
                </button>
              )}
            </div>
          </div>
        </div>
      )}

    </div>
  )
}
