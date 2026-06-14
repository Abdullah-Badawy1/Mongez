import React from 'react';
import { adminAPI } from '../../services/api';
import Table from '../../components/admin/Table';
import { usePolling, useTimeAgo } from '../../hooks/usePolling';

const fetchRatings = () => adminAPI.ratings.list().then((res) => res.data || []);

const Ratings = () => {
  // 30 s — ratings only land at order-complete time, so we don't need a
  // tight loop here.
  const { data: ratings, loading, lastUpdatedAt, refresh } =
    usePolling(fetchRatings, { intervalMs: 30_000, initialData: [] });
  const updatedLabel = useTimeAgo(lastUpdatedAt);

  const columns = [
    { key: 'id', label: 'Rating #' },
    {
      key: 'order',
      label: 'Order',
      render: (row) => `#${row.order}`,
    },
    {
      key: 'client_name',
      label: 'Client',
      render: (row) => row.client_name || 'N/A',
    },
    {
      key: 'stars',
      label: 'Stars',
      render: (row) => (
        <span style={{ color: '#f59e0b' }}>
          {'★'.repeat(row.stars)}{'☆'.repeat(5 - row.stars)}
        </span>
      ),
    },
    {
      key: 'review',
      label: 'Review',
      render: (row) => row.review || <span className="text-muted">-</span>,
    },
    {
      key: 'created_at',
      label: 'Date',
      render: (row) => new Date(row.created_at).toLocaleDateString(),
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
