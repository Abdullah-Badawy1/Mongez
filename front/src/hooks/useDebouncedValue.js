import { useEffect, useState } from 'react';

/**
 * Returns a debounced copy of `value` that only changes after the input
 * has been stable for `delay` ms. Use for search inputs that drive
 * network fetchers — without debouncing every keystroke triggers a
 * request, which feels slow and floods the backend.
 *
 *   const [search, setSearch] = useState('');
 *   const debouncedSearch = useDebouncedValue(search, 300);
 *   const fetcher = useCallback(() => api.list({ search: debouncedSearch }),
 *                                [debouncedSearch]);
 */
export function useDebouncedValue(value, delay = 300) {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);
  return debounced;
}
