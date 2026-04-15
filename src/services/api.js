// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE LAYER
// All data fetching lives here. Pages never import from /data directly.
//
// HOW TO SWITCH TO A REAL BACKEND:
//   1. npm install axios
//   2. Uncomment the axios client block below
//   3. Add VITE_API_BASE_URL=http://localhost:8000/api to your .env file
//   4. In each function, remove the fakeDelay line and
//      uncomment the axios call directly beneath it.
// ─────────────────────────────────────────────────────────────────────────────

// import axios from 'axios'
//
// const client = axios.create({
//   baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api',
//   headers: { 'Content-Type': 'application/json' },
// })

import { summaryCards }      from '../data/dashboardData'
import { sites }             from '../data/sitesData'
import { initialComplaints } from '../data/complaintsData'
import {
  wasteByMonth,
  wasteLast30,
  wasteLast7,
  complianceData,
  analyticsSummary,
} from '../data/analyticsData'

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Simulates an async network call with a short delay.
 * Returns { data } to mirror the axios response shape.
 * Replace with real axios calls when the backend is ready.
 */
const fakeDelay = (data, ms = 400) =>
  new Promise(resolve => setTimeout(() => resolve({ data }), ms))

/**
 * Normalises any thrown value into a consistent, user-friendly string.
 * Handles axios errors, network errors, Error instances, and plain strings.
 */
function normaliseError(err) {
  if (!err) return 'Something went wrong. Please try again.'
  // Axios error with a structured response body
  if (err?.response?.data?.message) return String(err.response.data.message)
  // Axios / fetch network failure
  if (err?.message === 'Network Error') return 'Network error. Please check your connection.'
  // Standard Error object or anything with a message string
  if (err?.message) return String(err.message)
  // Plain string thrown directly
  if (typeof err === 'string') return err
  // Unknown shape — safe fallback
  return 'Something went wrong. Please try again.'
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Fetch summary card metrics shown on the Dashboard page.
 *
 * Real call:
 *   const res = await client.get('/get-dashboard-data')
 *   return res.data
 */
export async function getDashboardData() {
  try {
    const res = await fakeDelay(summaryCards)
    // const res = await client.get('/get-dashboard-data')
    return res.data
  } catch (err) {
    throw new Error(normaliseError(err))
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SITES
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Fetch the full list of waste collection sites.
 *
 * Real call:
 *   const res = await client.get('/get-sites')
 *   return res.data
 */
export async function getSites() {
  try {
    const res = await fakeDelay(sites)
    // const res = await client.get('/get-sites')
    return res.data
  } catch (err) {
    throw new Error(normaliseError(err))
  }
}

/**
 * Fetch a single site by ID.
 *
 * Real call:
 *   const res = await client.get(`/get-sites/${id}`)
 *   return res.data
 */
export async function getSiteById(id) {
  try {
    const res = await fakeDelay(sites.find(s => s.id === id) || null)
    // const res = await client.get(`/get-sites/${id}`)
    return res.data
  } catch (err) {
    throw new Error(normaliseError(err))
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPLAINTS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Fetch all complaints with their current status.
 *
 * Real call:
 *   const res = await client.get('/get-complaints')
 *   return res.data
 */
export async function getComplaints() {
  try {
    const res = await fakeDelay(initialComplaints)
    // const res = await client.get('/get-complaints')
    return res.data
  } catch (err) {
    throw new Error(normaliseError(err))
  }
}

/**
 * Mark a complaint as resolved.
 *
 * Real call:
 *   const res = await client.patch(`/complaints/${id}/resolve`)
 *   return res.data
 */
export async function resolveComplaint(id) {
  try {
    const res = await fakeDelay({ id, status: 'Resolved' })
    // const res = await client.patch(`/complaints/${id}/resolve`)
    return res.data
  } catch (err) {
    throw new Error(normaliseError(err))
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANALYTICS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Fetch analytics data for a given date range.
 * @param {'Last 7 Days'|'Last 30 Days'|'Last 6 Months'} range
 *
 * Real call:
 *   const res = await client.get('/get-analytics', { params: { range } })
 *   return res.data
 */
export async function getAnalyticsData(range = 'Last 6 Months') {
  try {
    const chartMap = {
      'Last 7 Days':   wasteLast7,
      'Last 30 Days':  wasteLast30,
      'Last 6 Months': wasteByMonth,
    }
    const res = await fakeDelay({
      chart:      chartMap[range] ?? wasteByMonth,
      compliance: complianceData,
      summary:    analyticsSummary,
    })
    // const res = await client.get('/get-analytics', { params: { range } })
    return res.data
  } catch (err) {
    throw new Error(normaliseError(err))
  }
}
