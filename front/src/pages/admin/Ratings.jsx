import React from 'react';
import { adminAPI } from '../../services/api';
import Table from '../../components/admin/Table';
import { usePolling, useTimeAgo } from '../../hooks/usePolling';

const fetchRatings = () => adminAPI.ratings.list().then((res) => res.data || []);

const Ratings = () => {
  // 5 s — when an order completes we want the new rating to surface on
  // the moderation page right away.
  const { data: ratings, loading, lastUpdatedAt, refresh } =
    usePolling(fetchRatings, { intervalMs: 5_000, initialData: [] });
  const updatedLabel = useTimeAgo(lastUpdatedAt);

  const fmtDate = (iso) => {
    const d = new Date(iso);
    return d.toLocaleString(undefined, {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    });
  };

  const columns = [
    {
      key: 'order',
      label: 'Order',
      render: (row) => (
        <div>
          <div style={{ fontWeight: 600, color: '#1e293b' }}>#{row.order_id}</div>
          <div className="text-muted" style={{ fontSize: '12px' }}>
            {row.order_category || '—'}
          </div>
        </div>
      ),
    },
    {
      key: 'client',
      label: 'Client',
      render: (row) => (
        <div>
          <div style={{ fontWeight: 500 }}>
            {row.client_name || row.client_username || 'N/A'}
          </div>
          {row.client_username && row.client_name ? (
            <div className="text-muted" style={{ fontSize: '12px' }}>@{row.client_username}</div>
          ) : null}
        </div>
      ),
    },
    {
      key: 'worker',
      label: 'Worker',
      render: (row) => (
        <div>
          <div style={{ fontWeight: 500 }}>
            {row.worker_name || row.worker_username || 'N/A'}
          </div>
          {row.worker_profession ? (
            <div className="text-muted" style={{ fontSize: '12px' }}>{row.worker_profession}</div>
          ) : null}
        </div>
      ),
    },
    {
      key: 'stars',
      label: 'Stars',
      render: (row) => (
        <span style={{ color: '#f59e0b', whiteSpace: 'nowrap' }}>
          {'★'.repeat(row.stars)}{'☆'.repeat(5 - row.stars)}
          <span className="text-muted ms-2" style={{ fontSize: '12px' }}>
            {row.stars}/5
          </span>
        </span>
      ),
    },
    {
      key: 'review',
      label: 'Review',
      render: (row) =>
        row.review
          ? <span title={row.review} style={{ display: 'inline-block', maxWidth: '240px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', verticalAlign: 'middle' }}>{row.review}</span>
          : <span className="text-muted">—</span>,
    },
    {
      key: 'created_at',
      label: 'Date',
      render: (row) => (
        <span style={{ fontSize: '13px', color: '#475569' }}>
          {fmtDate(row.created_at)}
        </span>
      ),
    },
  ];

  const avgStars = ratings.length
    ? (ratings.reduce((sum, r) => sum + r.stars, 0) / ratings.length).toFixed(1)
    : '0.0';

  return (
    <div>
      <div className="page-header d-flex justify-content-between align-items-start flex-wrap gap-2">
        <div>
          <h4 className="mb-1">Ratings & Reviews</h4>
          <p className="mb-0">View all ratings and reviews left by clients.</p>
        </div>
        <div className="d-flex align-items-center gap-2">
          <span className="text-muted small">
            <i className="bi bi-arrow-clockwise me-1"></i>
            {updatedLabel ? `Updated ${updatedLabel}` : 'Loading…'}
          </span>
          <button type="button" className="btn btn-sm btn-outline-secondary" onClick={refresh} disabled={loading} title="Refresh now">
            <i className="bi bi-arrow-repeat"></i>
          </button>
        </div>
      </div>

      <div className="row g-4 mb-4">
        <div className="col-md-4">
          <div className="card border-0 shadow-sm" style={{ borderRadius: '12px' }}>
            <div className="card-body p-3 text-center">
              <p className="text-muted mb-1" style={{ fontSize: '12px' }}>Total Ratings</p>
              <h4 className="fw-bold mb-0" style={{ color: '#1e293b' }}>{ratings.length}</h4>
            </div>
          </div>
        </div>
        <div className="col-md-4">
          <div className="card border-0 shadow-sm" style={{ borderRadius: '12px' }}>
            <div className="card-body p-3 text-center">
              <p className="text-muted mb-1" style={{ fontSize: '12px' }}>Average Rating</p>
              <h4 className="fw-bold mb-0" style={{ color: '#f59e0b' }}>{avgStars} <i className="bi bi-star-fill" style={{ fontSize: '16px' }}></i></h4>
            </div>
          </div>
        </div>
        <div className="col-md-4">
          <div className="card border-0 shadow-sm" style={{ borderRadius: '12px' }}>
            <div className="card-body p-3 text-center">
              <p className="text-muted mb-1" style={{ fontSize: '12px' }}>With Reviews</p>
              <h4 className="fw-bold mb-0" style={{ color: '#8b5cf6' }}>{ratings.filter((r) => r.review).length}</h4>
            </div>
          </div>
        </div>
      </div>

      <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
        <div className="card-body p-4">
          <Table columns={columns} data={ratings} loading={loading} emptyMessage="No ratings found" />
        </div>
      </div>
    </div>
  );
};

export default Ratings;
