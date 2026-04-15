import React from 'react'
import './ErrorMessage.css'

/**
 * Reusable error display.
 * @param {string}   message  - User-friendly error text
 * @param {Function} onRetry  - Called when the user clicks "Try Again"
 */
export default function ErrorMessage({ message, onRetry }) {
  return (
    <div className="error-box">
      <span className="error-icon">⚠️</span>
      <p className="error-text">{message || 'Something went wrong. Please try again.'}</p>
      {onRetry && (
        <button className="error-retry-btn" onClick={onRetry}>
          Try Again
        </button>
      )}
    </div>
  )
}
