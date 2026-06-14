import { useCallback, useEffect, useRef, useState } from 'react';

/**
 * Tab-visibility-aware polling hook.
 *
 * Calls `fetcher` on mount, then again every `intervalMs`. Pauses while
 * the browser tab is hidden — refresh fires the moment the tab becomes
 * visible again so users never see stale data on tab-return. Returns the
 * latest data, loading flag, last error, the timestamp of the last
 * successful fetch, and a manual `refresh()`.
 *
 * `setData` is exposed so callers can do optimistic updates (mutate UI,
 * call API, revert on error).
 *
 *   const fetcher = useCallback(() => adminAPI.orders.list(), []);
 *   const { data, loading, lastUpdatedAt, refresh, setData } =
 *     usePolling(fetcher, { intervalMs: 10000, initialData: [] });
 *
 * `fetcher` should be a stable reference (wrap in useCallback) so the
 * polling timer doesn't tear down and rebuild on every render.
 */
export function usePolling(fetcher, { intervalMs = 10_000, initialData = null, enabled = true } = {}) {
  const [data, setData] = useState(initialData);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [lastUpdatedAt, setLastUpdatedAt] = useState(null);

  // Keep a ref to the current fetcher so the polling timer always sees
  // the freshest one without the effect tearing down on every render.
  const fetcherRef = useRef(fetcher);
  useEffect(() => { fetcherRef.current = fetcher; }, [fetcher]);

  // Manual refresh — doesn't gate on a mount flag (React only warns on
  // setState-after-unmount, doesn't crash; the warning is preferable to
  // a hang if the gate goes wrong).
  const refresh = useCallback(async () => {
    try {
      const result = await fetcherRef.current();
      setData(result);
      setError(null);
      setLastUpdatedAt(new Date());
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!enabled) {
      setLoading(false);
      return undefined;
    }

    // Track aliveness per-effect-instance so a StrictMode double-mount
    // (or a route change mid-flight) doesn't write to a torn-down tree.
    let alive = true;

    const run = async () => {
      try {
        const result = await fetcherRef.current();
        if (!alive) return;
        setData(result);
        setError(null);
        setLastUpdatedAt(new Date());
      } catch (err) {
        if (!alive) return;
        setError(err);
      } finally {
        if (alive) setLoading(false);
      }
    };

    const tick = () => {
      if (document.visibilityState !== 'visible') return;
      run();
    };

    run();
    const timer = setInterval(tick, intervalMs);

    // Refresh immediately on tab-return so the user sees fresh data right
    // away rather than waiting up to `intervalMs`.
    const onVisibility = () => {
      if (document.visibilityState === 'visible') run();
    };
    document.addEventListener('visibilitychange', onVisibility);

    return () => {
      alive = false;
      clearInterval(timer);
      document.removeEventListener('visibilitychange', onVisibility);
    };
  }, [intervalMs, enabled]);

  return { data, loading, error, lastUpdatedAt, refresh, setData };
}

/**
 * Small helper for rendering "Updated 5s ago" / "Updated 2 min ago" labels
 * next to a polling page. Re-renders every second.
 */
export function useTimeAgo(date) {
  const [nowMs, setNowMs] = useState(() => Date.now());
  useEffect(() => {
    if (!date) return undefined;
    const id = setInterval(() => setNowMs(Date.now()), 1000);
    return () => clearInterval(id);
  }, [date]);

  if (!date) return '';
  const seconds = Math.floor((nowMs - date.getTime()) / 1000);
  if (seconds < 5) return 'just now';
  if (seconds < 60) return `${seconds}s ago`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.floor(minutes / 60);
  return `${hours} h ago`;
}
