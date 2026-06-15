import React, { useState, useCallback } from 'react';
import { adminAPI } from '../../services/api';
import Table from '../../components/admin/Table';
import { usePolling, useTimeAgo } from '../../hooks/usePolling';

const Workers = () => {
  const [search, setSearch] = useState('');
  const [profileFilter, setProfileFilter] = useState(''); // '', 'complete', 'incomplete'
  const [selectedWorker, setSelectedWorker] = useState(null);

  const fetchWorkers = useCallback(async () => {
    const params = { page_size: 50 };
    if (search) params.search = search;
    if (profileFilter) params.status = profileFilter;
    const res = await adminAPI.workers.list(params);
    return res.data;
  }, [search, profileFilter]);

  // 30 s — worker profiles change slowly (rating updates, availability).
  const { data, loading, lastUpdatedAt, refresh } =
    usePolling(fetchWorkers, { intervalMs: 10_000, initialData: { results: [], count: 0, complete_count: 0, incomplete_count: 0 } });
  const workers = data?.results || [];
  const total = data?.count || 0;
  const completeCount = data?.complete_count || 0;
  const incompleteCount = data?.incomplete_count || 0;
  const totalWorkers = completeCount + incompleteCount;
  const completionPct = totalWorkers ? Math.round((completeCount / totalWorkers) * 100) : 0;
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
    {
      key: 'user',
      label: 'Worker',
      render: (row) => (
        <div className="d-flex align-items-center gap-2">
          <div className="rounded-circle d-flex align-items-center justify-content-center" style={{ width: '36px', height: '36px', backgroundColor: '#f59e0b15', color: '#f59e0b', fontSize: '14px', fontWeight: '700' }}>
            {row.user?.username?.[0]?.toUpperCase() || '?'}
          </div>
          <div>
            <div style={{ fontWeight: 600, color: '#1e293b' }}>
              {row.user?.display_name || row.user?.username || 'N/A'}
            </div>
            <div className="text-muted" style={{ fontSize: '12px' }}>
              {row.user?.phone || '—'}
            </div>
          </div>
        </div>
      ),
    },
    {
      key: 'profession',
      label: 'Profession',
      render: (row) => row.has_profile
        ? (
          <div>
            <div style={{ fontWeight: 500 }}>{row.profession || '—'}</div>
            {row.profession_ar ? (
              <div className="text-muted" style={{ fontSize: '12px' }}>{row.profession_ar}</div>
            ) : null}
          </div>
        )
        : <span className="badge rounded-pill" style={{ backgroundColor: '#fef3c7', color: '#92400e' }}>Not set up</span>,
    },
    {
      key: 'has_profile',
      label: 'Onboarding',
      render: (row) => row.has_profile
        ? <span className="badge rounded-pill" style={{ backgroundColor: '#dcfce7', color: '#166534' }}>Complete</span>
        : <span className="badge rounded-pill" style={{ backgroundColor: '#fef3c7', color: '#92400e' }}>Incomplete</span>,
    },
    {
      key: 'average_rating',
      label: 'Rating',
      render: (row) => row.has_profile
        ? (
          <span>
            {(row.average_rating || 0).toFixed(1)}
            <i className="bi bi-star-fill ms-1" style={{ color: '#f59e0b', fontSize: '12px' }}></i>
          </span>
        )
        : <span className="text-muted">—</span>,
    },
    {
      key: 'completed_jobs',
      label: 'Jobs',
      render: (row) => row.has_profile
        ? <span>{row.completed_jobs}</span>
        : <span className="text-muted">—</span>,
    },
    {
      key: 'accept_rate',
      label: 'Accept %',
      render: (row) => row.has_profile
        ? <span>{Math.round(row.accept_rate || 0)}%</span>
        : <span className="text-muted">—</span>,
    },
    {
      key: 'is_available',
      label: 'Available',
      render: (row) => row.has_profile
        ? (
          <span className={`badge rounded-pill px-3 py-1 ${row.is_available ? '' : ''}`} style={{ backgroundColor: row.is_available ? '#dcfce7' : '#e2e8f0', color: row.is_available ? '#166534' : '#475569' }}>
            {row.is_available ? 'Online' : 'Offline'}
          </span>
        )
        : <span className="text-muted">—</span>,
    },
    {
      key: 'actions',
      label: '',
      render: (row) => (
        <button
          className="btn btn-sm"
          style={{ color: '#6366f1', background: '#6366f110', borderRadius: '8px' }}
          onClick={() => viewDetail(row)}
          title="View Details"
          disabled={!row.has_profile || !row.id}
        >
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
        </div>
      </div>

      {/* Onboarding banner — only show if there are incomplete workers */}
      {incompleteCount > 0 && (
        <div className="card border-0 mb-3" style={{ borderRadius: '15px', background: 'linear-gradient(135deg, #fff7ed 0%, #fef3c7 100%)' }}>
          <div className="card-body p-3 p-md-4">
            <div className="d-flex flex-wrap align-items-center gap-3">
              <div className="rounded-circle d-flex align-items-center justify-content-center" style={{ width: '52px', height: '52px', backgroundColor: '#f59e0b25', color: '#b45309' }}>
                <i className="bi bi-person-exclamation fs-3"></i>
              </div>
              <div className="flex-grow-1">
                <div className="fw-bold" style={{ color: '#92400e', fontSize: '15px' }}>
                  {incompleteCount} of {totalWorkers} worker accounts haven't finished onboarding
                </div>
                <div style={{ color: '#92400e', fontSize: '13px', opacity: 0.85 }}>
                  These users registered as workers but never picked a service / set their experience.
                  They won't appear in the client app until they complete the "Add service" step.
                </div>
                <div className="mt-2 d-flex align-items-center gap-2" style={{ fontSize: '12px' }}>
                  <div className="progress flex-grow-1" style={{ height: '6px', maxWidth: '300px' }}>
                    <div className="progress-bar" style={{ width: `${completionPct}%`, backgroundColor: '#10b981' }}></div>
                  </div>
                  <span style={{ color: '#92400e' }}>{completionPct}% complete</span>
                </div>
              </div>
              <button
                className="btn btn-sm"
                style={{ background: '#92400e', color: 'white', borderRadius: '8px', padding: '6px 14px' }}
                onClick={() => setProfileFilter('incomplete')}
              >
                Show incomplete
              </button>
            </div>
          </div>
        </div>
      )}

      <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
        <div className="card-body p-4">
          <div className="row mb-3 g-2">
            <div className="col-md-5">
              <div className="input-group" style={{ borderRadius: '10px', overflow: 'hidden' }}>
                <span className="input-group-text bg-white border-end-0"><i className="bi bi-search text-muted"></i></span>
                <input type="text" className="form-control border-start-0" placeholder="Search workers by name or phone..."
                  value={search} onChange={(e) => setSearch(e.target.value)}
                  style={{ padding: '10px 14px' }} />
              </div>
            </div>
            <div className="col-md-4">
              <select className="form-select" value={profileFilter} onChange={(e) => setProfileFilter(e.target.value)} style={{ padding: '10px 15px', borderRadius: '10px' }}>
                <option value="">All workers ({totalWorkers})</option>
                <option value="complete">Onboarded ({completeCount})</option>
                <option value="incomplete">Incomplete ({incompleteCount})</option>
              </select>
            </div>
            <div className="col-md-3 text-md-end small text-muted d-flex align-items-center justify-content-md-end">
              <span>Showing {workers.length} of {total} matching</span>
            </div>
          </div>
          <Table columns={columns} data={workers} loading={loading} emptyMessage="No workers match the current filter" />
        </div>
      </div>

      {/* Worker Detail Modal */}
      {selectedWorker && (
        <div className="modal d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content" style={{ borderRadius: '15px', border: 'none' }}>
              <div className="modal-header border-0">
                <h5 className="modal-title fw-bold">Worker details</h5>
                <button type="button" className="btn-close" onClick={() => setSelectedWorker(null)}></button>
              </div>
              <div className="modal-body pt-0">
                <div className="text-center mb-4">
                  <div className="rounded-circle d-flex align-items-center justify-content-center mx-auto mb-2" style={{ width: '72px', height: '72px', backgroundColor: '#f59e0b20', color: '#f59e0b', fontSize: '26px', fontWeight: '700' }}>
                    {selectedWorker.user?.username?.[0]?.toUpperCase() || '?'}
                  </div>
                  <h5 className="fw-bold mb-0">{selectedWorker.user?.display_name || selectedWorker.user?.username}</h5>
                  <span className="text-muted" style={{ fontSize: '13px' }}>{selectedWorker.user?.phone || 'No phone'}</span>
                  {selectedWorker.is_verified ? (
                    <div className="mt-1">
                      <span className="badge rounded-pill px-3 py-1" style={{ backgroundColor: '#dbeafe', color: '#1d4ed8' }}>
                        <i className="bi bi-patch-check-fill me-1"></i>Verified
                      </span>
                    </div>
                  ) : null}
                </div>
                <div className="row g-3">
                  <div className="col-6">
                    <div className="p-3 rounded-3" style={{ backgroundColor: '#f8fafc' }}>
                      <p className="text-muted mb-0" style={{ fontSize: '12px' }}>Profession</p>
                      <p className="fw-bold mb-0" style={{ fontSize: '14px' }}>{selectedWorker.profession || '—'}</p>
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
                        {(selectedWorker.average_rating || 0).toFixed(1)} <i className="bi bi-star-fill" style={{ fontSize: '12px' }}></i>
                      </p>
                    </div>
                  </div>
                  <div className="col-6">
                    <div className="p-3 rounded-3" style={{ backgroundColor: '#f8fafc' }}>
                      <p className="text-muted mb-0" style={{ fontSize: '12px' }}>Jobs completed</p>
                      <p className="fw-bold mb-0" style={{ fontSize: '14px' }}>{selectedWorker.completed_jobs || 0}</p>
                    </div>
                  </div>
                  <div className="col-6">
                    <div className="p-3 rounded-3" style={{ backgroundColor: '#f8fafc' }}>
                      <p className="text-muted mb-0" style={{ fontSize: '12px' }}>Accept rate</p>
                      <p className="fw-bold mb-0" style={{ fontSize: '14px' }}>{Math.round(selectedWorker.accept_rate || 0)}%</p>
                    </div>
                  </div>
                  <div className="col-6">
                    <div className="p-3 rounded-3" style={{ backgroundColor: '#f8fafc' }}>
                      <p className="text-muted mb-0" style={{ fontSize: '12px' }}>Availability</p>
                      <p className="fw-bold mb-0" style={{ fontSize: '14px' }}>
                        <span className="badge rounded-pill px-3 py-1" style={{ backgroundColor: selectedWorker.is_available ? '#dcfce7' : '#e2e8f0', color: selectedWorker.is_available ? '#166534' : '#475569' }}>
                          {selectedWorker.is_available ? 'Online' : 'Offline'}
                        </span>
                      </p>
                    </div>
                  </div>
                </div>
                {selectedWorker.bio ? (
                  <div className="mt-3">
                    <p className="text-muted mb-1" style={{ fontSize: '12px' }}>Bio</p>
                    <p style={{ fontSize: '14px', color: '#475569' }}>{selectedWorker.bio}</p>
                  </div>
                ) : null}
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
