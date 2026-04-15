import React from 'react'
import './Spinner.css'

export default function Spinner() {
  return (
    <div className="spinner-overlay">
      <div className="spinner-circle" />
      <p className="spinner-label">Loading...</p>
    </div>
  )
}
