import React, { useState, useCallback } from 'react';
import { adminAPI } from '../../services/api';
import Table from '../../components/admin/Table';
import { usePolling, useTimeAgo } from '../../hooks/usePolling';

const Workers = () => {
  const [search, setSearch] = useState('');
  const [selectedWorker, setSelectedWorker] = useState(null);

  const fetchWorkers = useCallback(async () => {
    const params = { page_size: 50 };
    if (search) params.search = search;
    const res = await adminAPI.workers.list(params);
    return res.data?.results || [];
  }, [search]);

  // 30 s — worker profiles change slowly (rating updates, availability).
  const { data: workers, loading, lastUpdatedAt, refresh } =
    usePolling(fetchWorkers, { intervalMs: 30_000, initialData: [] });
  const updatedLabel = useTimeAgo(lastUpdatedAt);

  const viewDetail = async (worker) => {
    try {
      const res = await adminAPI.workers.detail(worker.id);
      setSelectedWorker(res.data);
    } catch {
      alert('Failed to load worker details');
    }
  };

  const columns = [
    { key: 'id', label: 'ID' },
    {
      key: 'user',
      label: 'Username',
      render: (row) => (
        <div className="d-flex align-items-center gap-2">
          <div className="rounded-circle d-flex align-items-center justify-content-center" style={{ width: '28px', height: '28px', backgroundColor: '#f59e0b15', color: '#f59e0b', fontSize: '12px', fontWeight: '600' }}>
            {row.user?.username?.[0]?.toUpperCase() || '?'}
          </div>
          {row.user?.username || 'N/A'}
        </div>
      ),
    },
    {
      key: 'category',
      label: 'Category',
      render: (row) => row.category?.name || 'N/A',
    },
    {
      key: 'experience_years',
      label: 'Experience',
      render: (row) => `${row.experience_years || 0} yrs`,
    },
    {
      key: 'average_rating',
      label: 'Rating',
      render: (row) => (
        <span>
          {row.average_rating?.toFixed(1) || '0.0'}
          <i className="bi bi-star-fill ms-1" style={{ color: '#f59e0b', fontSize: '12px' }}></i>
        </span>
      ),
    },
    {
      key: 'completed_jobs',
      label: 'Jobs Done',
    },
    {
      key: 'has_profile',
      label: 'Profile',
      render: (row) => (
        <span className={`badge ${row.has_profile ? 'bg-success' : 'bg-warning'} rounded-pill`}>
          {row.has_profile ? 'Complete' : 'Incomplete'}
        </span>
      ),
    },
    {
      key: 'is_available',
      label: 'Available',
      render: (row) => (
        row.has_profile ? (
          <span className={`badge ${row.is_available ? 'bg-success' : 'bg-secondary'} rounded-pill`}>
            {row.is_available ? 'Yes' : 'No'}
          </span>
        ) : <span className="text-muted">-</span>
      ),
    },
    {
      key: 'actions',
      label: '',
      render: (row) => (
        <button className="btn btn-sm" style={{ color: '#f59e0b', background: '#f59e0b10', borderRadius: '8px' }} onClick={() => viewDetail(row)} title="View Details" disabled={!row.has_profile || !row.id}>
          <i className="bi bi-eye"></i>
        </button>
      ),
    },
  ];

  return (
    <div>
      <div className="page-header d-flex justify-content-between align-items-center flex-wrap gap-2">
        <div>
          <h4 className="mb-1">Workers Management</h4>
          <p className="mb-0">View all registered workers and their details.</p>
        </div>
        <div className="d-flex align-items-center gap-2">
          <span className="text-muted small">
            <i className="bi bi-arrow-clockwise me-1"></i>
            {updatedLabel ? `Updated ${updatedLabel}` : 'Loading…'}
          </span>
          <button type="button" className="btn btn-sm btn-outline-secondary" onClick={refresh} disabled={loading} title="Refresh now">
            <i className="bi bi-arrow-repeat"></i>
          </button>
          <div style={{ maxWidth: '300px', width: '100%' }}>
            <div className="input-group" style={{ borderRadius: '10px', overflow: 'hidden' }}>
              <span className="input-group-text bg-white border-end-0"><i className="bi bi-search text-muted"></i></span>
              <input type="text" className="form-control border-start-0" placeholder="Search workers..." value={search} onChange={(e) => setSearch(e.target.value)} style={{ padding: '8px 12px' }} />
            </div>
          </div>
        </div>
      </div>

      <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
        <div className="card-body p-4">
          <Table columns={columns} data={workers} loading={loading} emptyMessage="No workers found" />
        </div>
      </div>

      {/* Worker Detail Modal */}
      {selectedWorker && (
        <div className="modal d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content" style={{ borderRadius: '15px', border: 'none' }}>
              <div className="modal-header border-0">
                <h5 className="modal-title fw-bold">Worker Details</h5>
                <button type="button" className="btn-close" onClick={() => setSelectedWorker(null)}></button>
              </div>
              <div className="modal-body pt-0">
                <div className="text-center mb-4">
                  <div className="rounded-circle d-flex align-items-center justify-content-center mx-auto mb-2" style={{ width: '64px', height: '64px', backgroundColor: '#f59e0b20', color: '#f59e0b', fontSize: '24px', fontWeight: '700' }}>
                    {selectedWorker.user?.username?.[0]?.toUpperCase() || '?'}
                  </div>
                  <h5 className="fw-bold mb-0">{selectedWorker.user?.username}</h5>
                  <span className="text-muted" style={{ fontSize: '13px' }}>{selectedWorker.user?.phone || 'No phone'}</span>
                  {!selectedWorker.has_profile && (
                    <div className="mt-2">
                      <span className="badge bg-warning rounded-pill px-3 py-2">No profile created yet</span>
                    </div>
                  )}
                </div>
                {selectedWorker.has_profile ? (
                  <div className="row g-3">
                    <div className="col-6">
                      <div className="p-3 rounded-3" style={{ backgroundColor: '#f8fafc' }}>
                        <p className="text-muted mb-0" style={{ fontSize: '12px' }}>Category</p>
                        <p className="fw-bold mb-0" style={{ fontSize: '14px' }}>{selectedWorker.category?.name || 'N/A'}</p>
                      </div>
                    </div>
                    <div className="col-6">
                      <div className="p-3 rounded-3" style={{ backgroundColor: '#f8fafc' }}>
                        <p className="text-muted mb-0" style={{ fontSize: '12px' }}>Experience</p>
                        <p className="fw-bold mb-0" style={{ fontSize: '14px' }}>{selectedWorker.experience_years || 0} years</p>
                      </div>
                    </div>
                    <div className="col-6">
                      <div className="p-3 rounded-3" style={{ backgroundColor: '#f8fafc' }}>
                        <p className="text-muted mb-0" style={{ fontSize: '12px' }}>Rating</p>
                        <p className="fw-bold mb-0" style={{ fontSize: '14px', color: '#f59e0b' }}>
                          {selectedWorker.average_rating?.toFixed(1) || '0.0'} <i className="bi bi-star-fill" style={{ fontSize: '12px' }}></i>
                        </p>
                      </div>
                    </div>
                    <div className="col-6">
                      <div className="p-3 rounded-3" style={{ backgroundColor: '#f8fafc' }}>
                        <p className="text-muted mb-0" style={{ fontSize: '12px' }}>Jobs Completed</p>
                        <p className="fw-bold mb-0" style={{ fontSize: '14px' }}>{selectedWorker.completed_jobs || 0}</p>
                      </div>
                    </div>
                    <div className="col-6">
                      <div className="p-3 rounded-3" style={{ backgroundColor: '#f8fafc' }}>
                        <p className="text-muted mb-0" style={{ fontSize: '12px' }}>Score</p>
                        <p className="fw-bold mb-0" style={{ fontSize: '14px', color: '#6366f1' }}>{selectedWorker.score || '0.00'}</p>
                      </div>
                    </div>
                    <div className="col-6">
                      <div className="p-3 rounded-3" style={{ backgroundColor: '#f8fafc' }}>
                        <p className="text-muted mb-0" style={{ fontSize: '12px' }}>Available</p>
                        <p className="fw-bold mb-0" style={{ fontSize: '14px' }}>
                          <span className={`badge ${selectedWorker.is_available ? 'bg-success' : 'bg-secondary'} rounded-pill`}>
                            {selectedWorker.is_available ? 'Yes' : 'No'}
                          </span>
                        </p>
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="text-center py-4">
                    <i className="bi bi-person-x fs-1 text-muted d-block mb-2"></i>
                    <p className="text-muted">This worker has not created a profile yet.</p>
                  </div>
                )}
                {selectedWorker.description && (
                  <div className="mt-3">
                    <p className="text-muted mb-1" style={{ fontSize: '12px' }}>Description</p>
                    <p style={{ fontSize: '14px', color: '#475569' }}>{selectedWorker.description}</p>
                  </div>
                )}
              </div>
              <div className="modal-footer border-0 pt-0">
                <button className="btn px-4" style={{ borderRadius: '10px', border: '1px solid #e2e8f0', color: '#475569' }} onClick={() => setSelectedWorker(null)}>Close</button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Workers;
