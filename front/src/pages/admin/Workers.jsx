import React, { useState, useCallback } from 'react';
import { adminAPI } from '../../services/api';
import Table from '../../components/admin/Table';
import { usePolling, useTimeAgo } from '../../hooks/usePolling';
import { useDebouncedValue } from '../../hooks/useDebouncedValue';
import ExportCsvButton from '../../components/admin/ExportCsvButton';

const emptyEditForm = {
  avatar: null,
  avatarPreview: null,
  is_verified: false,
  is_featured: false,
  is_available: true,
};

const Workers = () => {
  const [search, setSearch] = useState('');
  const [profileFilter, setProfileFilter] = useState(''); // '', 'complete', 'incomplete'
  const [selectedWorker, setSelectedWorker] = useState(null);
  const [editingWorker, setEditingWorker] = useState(null);
  const [editForm, setEditForm] = useState(emptyEditForm);
  const [editLoading, setEditLoading] = useState(false);
  const [editError, setEditError] = useState(null);

  // Debounce so typing in the search box doesn't fire one query per
  // keystroke.
  const debouncedSearch = useDebouncedValue(search, 300);

  const fetchWorkers = useCallback(async () => {
    const params = { page_size: 50 };
    if (debouncedSearch) params.search = debouncedSearch;
    if (profileFilter) params.status = profileFilter;
    const res = await adminAPI.workers.list(params);
    return res.data;
  }, [debouncedSearch, profileFilter]);

  // 4 s — admin moderation actions (verify/feature/availability) should
  // surface across other admin sessions quickly.
  const { data, loading, lastUpdatedAt, refresh } =
    usePolling(fetchWorkers, { intervalMs: 4_000, initialData: { results: [], count: 0, complete_count: 0, incomplete_count: 0 } });
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

  const openEdit = (worker) => {
    setEditingWorker(worker);
    setEditForm({
      avatar: null,
      avatarPreview: worker.user?.avatar_url || null,
      is_verified: !!worker.is_verified,
      is_featured: !!worker.is_featured,
      is_available: !!worker.is_available,
    });
    setEditError(null);
  };

  const submitEdit = async (e) => {
    e.preventDefault();
    if (!editingWorker) return;
    setEditLoading(true);
    setEditError(null);
    try {
      let payload;
      if (editForm.avatar instanceof File) {
        const fd = new FormData();
        fd.append('avatar', editForm.avatar);
        fd.append('is_verified', editForm.is_verified ? 'true' : 'false');
        fd.append('is_featured', editForm.is_featured ? 'true' : 'false');
        fd.append('is_available', editForm.is_available ? 'true' : 'false');
        payload = fd;
      } else {
        payload = {
          is_verified: editForm.is_verified,
          is_featured: editForm.is_featured,
          is_available: editForm.is_available,
        };
      }
      await adminAPI.workers.update(editingWorker.id, payload);
      setEditingWorker(null);
      refresh();
    } catch (err) {
      const data = err.response?.data;
      if (data && typeof data === 'object') {
        const lines = [];
        for (const [k, msgs] of Object.entries(data)) {
          const arr = Array.isArray(msgs) ? msgs : [msgs];
          arr.forEach((m) => lines.push(`${k}: ${m}`));
        }
        setEditError(lines.join('\n') || 'Update failed.');
      } else {
        setEditError(err.message || 'Update failed.');
      }
    } finally {
      setEditLoading(false);
    }
  };

  const columns = [
    {
      key: 'user',
      label: 'Worker',
      render: (row) => (
        <div className="d-flex align-items-center gap-2">
          <div className="rounded-circle d-flex align-items-center justify-content-center overflow-hidden" style={{ width: '36px', height: '36px', backgroundColor: '#f59e0b15', color: '#f59e0b', fontSize: '14px', fontWeight: '700' }}>
            {row.user?.avatar_url ? (
              <img src={row.user.avatar_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
            ) : (
              row.user?.username?.[0]?.toUpperCase() || '?'
            )}
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
        <div className="d-flex gap-1">
          <button
            className="btn btn-sm"
            style={{ color: '#6366f1', background: '#6366f110', borderRadius: '8px' }}
            onClick={() => viewDetail(row)}
            title="View details"
            disabled={!row.has_profile || !row.id}
          >
            <i className="bi bi-eye"></i>
          </button>
          <button
            className="btn btn-sm"
            style={{ color: '#f59e0b', background: '#f59e0b15', borderRadius: '8px' }}
            onClick={() => openEdit(row)}
            title="Edit worker"
            disabled={!row.has_profile || !row.id}
          >
            <i className="bi bi-pencil"></i>
          </button>
        </div>
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
          <ExportCsvButton fetcher={adminAPI.exports.workers} filename="workers.csv" />
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
                  <div className="rounded-circle d-flex align-items-center justify-content-center mx-auto mb-2 overflow-hidden" style={{ width: '72px', height: '72px', backgroundColor: '#f59e0b20', color: '#f59e0b', fontSize: '26px', fontWeight: '700' }}>
                    {selectedWorker.user?.avatar_url ? (
                      <img src={selectedWorker.user.avatar_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                    ) : (
                      selectedWorker.user?.username?.[0]?.toUpperCase() || '?'
                    )}
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

      {/* Worker Edit Modal */}
      {editingWorker && (
        <div className="modal d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content" style={{ borderRadius: '15px', border: 'none' }}>
              <div className="modal-header border-0">
                <h5 className="modal-title fw-bold">
                  Edit {editingWorker.user?.display_name || editingWorker.user?.username || 'worker'}
                </h5>
                <button type="button" className="btn-close" onClick={() => setEditingWorker(null)}></button>
              </div>
              <form onSubmit={submitEdit}>
                <div className="modal-body pt-0">
                  {editError && (
                    <div className="alert alert-danger py-2 px-3" style={{ borderRadius: '10px', fontSize: '13px', border: 'none' }}>
                      <i className="bi bi-exclamation-circle me-1"></i>
                      {editError.split('\n').map((line, i) => <div key={i}>{line}</div>)}
                    </div>
                  )}
                  <div className="mb-3 d-flex align-items-center gap-3">
                    <div style={{
                      width: 72, height: 72, borderRadius: '50%',
                      background: '#f1f5f9', overflow: 'hidden',
                      display: 'flex', alignItems: 'center',
                      justifyContent: 'center', color: '#94a3b8',
                      fontWeight: 700, fontSize: 26, flexShrink: 0,
                    }}>
                      {editForm.avatar instanceof File ? (
                        <img alt="" src={URL.createObjectURL(editForm.avatar)}
                             style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      ) : editForm.avatarPreview ? (
                        <img alt="" src={editForm.avatarPreview}
                             style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      ) : (
                        (editingWorker.user?.username?.[0] || '?').toUpperCase()
                      )}
                    </div>
                    <div className="flex-grow-1">
                      <label className="form-label mb-1" style={{ fontSize: '13px', fontWeight: 500 }}>
                        Profile picture
                      </label>
                      <input
                        className="form-control"
                        type="file"
                        accept="image/*"
                        onChange={(e) => setEditForm({ ...editForm, avatar: e.target.files[0] || null })}
                        style={{ borderRadius: '10px' }}
                      />
                      {editForm.avatar instanceof File && (
                        <button type="button" className="btn btn-link btn-sm p-0 mt-1" style={{ fontSize: 12 }}
                                onClick={() => setEditForm({ ...editForm, avatar: null })}>
                          Cancel selection
                        </button>
                      )}
                    </div>
                  </div>

                  <div className="form-check form-switch mb-2">
                    <input className="form-check-input" type="checkbox" id="workerVerified"
                           checked={editForm.is_verified}
                           onChange={(e) => setEditForm({ ...editForm, is_verified: e.target.checked })} />
                    <label className="form-check-label" htmlFor="workerVerified" style={{ fontSize: '14px' }}>
                      <i className="bi bi-patch-check-fill me-1" style={{ color: '#1d4ed8' }}></i>
                      Verified worker
                    </label>
                  </div>
                  <div className="form-check form-switch mb-2">
                    <input className="form-check-input" type="checkbox" id="workerFeatured"
                           checked={editForm.is_featured}
                           onChange={(e) => setEditForm({ ...editForm, is_featured: e.target.checked })} />
                    <label className="form-check-label" htmlFor="workerFeatured" style={{ fontSize: '14px' }}>
                      <i className="bi bi-star-fill me-1" style={{ color: '#f59e0b' }}></i>
                      Featured on the homepage
                    </label>
                  </div>
                  <div className="form-check form-switch">
                    <input className="form-check-input" type="checkbox" id="workerAvailable"
                           checked={editForm.is_available}
                           onChange={(e) => setEditForm({ ...editForm, is_available: e.target.checked })} />
                    <label className="form-check-label" htmlFor="workerAvailable" style={{ fontSize: '14px' }}>
                      <i className="bi bi-circle-fill me-1" style={{ color: '#10b981', fontSize: '10px' }}></i>
                      Available for orders
                    </label>
                  </div>
                </div>
                <div className="modal-footer border-0 pt-0">
                  <button type="button" className="btn px-4"
                          style={{ borderRadius: '10px', border: '1px solid #e2e8f0', color: '#475569' }}
                          onClick={() => setEditingWorker(null)}>Cancel</button>
                  <button type="submit" className="btn px-4 text-white"
                          style={{ borderRadius: '10px', background: '#f59e0b', border: 'none' }}
                          disabled={editLoading}>
                    {editLoading ? <span className="spinner-border spinner-border-sm me-2"></span> : null}
                    Save changes
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Workers;
