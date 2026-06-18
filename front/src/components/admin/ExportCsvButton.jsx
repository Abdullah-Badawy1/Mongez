import { useState } from 'react';

/**
 * Triggers a CSV download from the given async fetcher. Fetcher must
 * return an axios response with `data` as a Blob (use `responseType:
 * 'blob'` on the axios call). The button shows a small spinner while
 * the request is in flight and re-enables itself on completion.
 */
export default function ExportCsvButton({ fetcher, filename, label = 'Export CSV' }) {
  const [loading, setLoading] = useState(false);

  const onClick = async () => {
    if (loading) return;
    setLoading(true);
    try {
      const res = await fetcher();
      const blob = res.data instanceof Blob
        ? res.data
        : new Blob([res.data], { type: 'text/csv;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error('Export failed:', err);
      const msg = err.response?.data?.error || 'Export failed.';
      alert(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <button
      type="button"
      className="btn btn-sm btn-outline-success"
      onClick={onClick}
      disabled={loading}
      title="Download CSV"
    >
      {loading ? (
        <>
          <span className="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>
          Exporting…
        </>
      ) : (
        <>
          <i className="bi bi-file-earmark-spreadsheet me-1"></i>
          {label}
        </>
      )}
    </button>
  );
}
