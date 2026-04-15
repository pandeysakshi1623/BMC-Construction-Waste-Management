import { useState, useEffect, useCallback, useRef } from 'react'

/**
 * Generic data-fetching hook.
 *
 * @param {Function} apiFn  - API service function (no args). Must return a Promise.
 *                            Pass a stable reference (module-level fn or useCallback).
 * @returns {{ data, loading, error, retry }}
 *   - data:    resolved value, null until loaded
 *   - loading: true while the request is in-flight
 *   - error:   user-friendly error string, null on success
 *   - retry:   re-runs the current apiFn (e.g. after an error)
 */
export default function useFetch(apiFn) {
  const [data, setData]       = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError]     = useState(null)

  // ── Retry counter ──────────────────────────────────────────────────────
  // Incrementing this is the ONLY way to manually re-trigger the effect.
  const [tick, setTick] = useState(0)
  const retry = useCallback(() => setTick(t => t + 1), [])

  // ── apiFn ref ──────────────────────────────────────────────────────────
  // Storing apiFn in a ref means we can safely include it in the effect's
  // dependency array via the ref VALUE (apiFnRef.current changes identity
  // when apiFn changes, but the ref object itself is stable).
  //
  // We track the apiFn reference in a separate counter so the fetch effect
  // re-runs whenever apiFn changes (e.g. Analytics changing dateRange via
  // useCallback) OR when retry() is called.
  const apiFnRef      = useRef(apiFn)
  const [apiFnTick, setApiFnTick] = useState(0)

  useEffect(() => {
    // When apiFn changes (new useCallback reference), bump apiFnTick so the
    // fetch effect below re-runs. Skip the very first render (ref already set).
    if (apiFnRef.current !== apiFn) {
      apiFnRef.current = apiFn
      setApiFnTick(t => t + 1)
    }
  }, [apiFn])

  // ── Fetch effect ───────────────────────────────────────────────────────
  useEffect(() => {
    let cancelled = false

    setLoading(true)
    setError(null)

    apiFnRef.current()
      .then(result => {
        if (!cancelled) setData(result)
      })
      .catch(err => {
        if (!cancelled) {
          setError(err?.message || 'Something went wrong. Please try again.')
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })

    // Cleanup: prevents setState on an unmounted component
    return () => { cancelled = true }

  }, [tick, apiFnTick]) // re-fetch on manual retry OR when apiFn reference changes

  return { data, loading, error, retry }
}
