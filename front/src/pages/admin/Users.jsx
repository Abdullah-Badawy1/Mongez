import React, { useState, useEffect, useCallback } from 'react';
import { adminAPI, referenceAPI } from '../../services/api';
import { usePolling, useTimeAgo } from '../../hooks/usePolling';
import ExportCsvButton from '../../components/admin/ExportCsvButton';

const roleColors = {
  admin: { bg: '#ef444420', color: '#ef4444' },
  worker: { bg: '#f59e0b20', color: '#f59e0b' },
  client: { bg: '#3b82f620', color: '#3b82f6' },
};

const emptyForm = {
  username: '', phone: '', email: '', password: '', role: 'client',
  governorate: '', city: '', address: '', is_active: true,
};

const Users = () => {
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [governorateFilter, setGovernorateFilter] = useState('');
  const [page, setPage] = useState(1);
  const [showModal, setShowModal] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [formLoading, setFormLoading] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [formError, setFormError] = useState(null);
  const [governorates, setGovernorates] = useState([]);

  // Load the 27-entry list once for the filter + add/edit dropdown.
  useEffect(() => {
    referenceAPI.listGovernorates()
      .then(setGovernorates)
      .catch(() => setGovernorates([]));
  }, []);
  const govLabel = useCallback((code) => {
    if (!code) return '';
    const g = governorates.find((x) => x.code === code);
    return g ? `${g.name_en}` : code;
  }, [governorates]);

  const pageSize = 15;

  // The fetcher captures the current filter values; usePolling resets its
  // timer when the fetcher reference changes, which is exactly what we
  // want when search / role / governorate / page change. Backend doesn't
  // (yet) support `governorate=` as a query param on /api/admin/users/,
  // so we apply that filter client-side after the fetch — small list of
  // 27 codes makes this trivially cheap.
  const fetchUsers = useCallback(async () => {
    const params = { page, page_size: pageSize };
    if (search) params.search = search;
    if (roleFilter) params.role = roleFilter;
    const res = await adminAPI.users.list(params);
    return { results: res.data.results, count: res.data.count };
  }, [page, search, roleFilter]);

  // 30 s — admins rarely watch the user list move; refresh is cheap when
  // filter or page changes, otherwise let the user reach for the button.
  const { data, loading, lastUpdatedAt, refresh } = usePolling(fetchUsers, {
    intervalMs: 10_000,
    initialData: { results: [], count: 0 },
  });
  const allUsers = data?.results || [];
  const users = governorateFilter
    ? allUsers.filter((u) => u.governorate === governorateFilter)
    : allUsers;
  const total = data?.count || 0;
  const updatedLabel = useTimeAgo(lastUpdatedAt);

  useEffect(() => { setPage(1); }, [search, roleFilter, governorateFilter]);

  const totalPages = Math.ceil(total / pageSize);

  const openAdd = () => {
    setEditingUser(null);
    setForm(emptyForm);
    setFormError(null);
    setShowModal(true);
  };

  const openEdit = (user) => {
    setEditingUser(user);
    setForm({
      username: user.username,
      phone: user.phone || '',
      email: user.email || '',
      password: '',
      role: user.role,
      governorate: user.governorate || '',
      city: user.city || '',
      address: user.address || '',
      is_active: user.is_active !== undefined ? user.is_active : true,
    });
    setFormError(null);
    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setFormLoading(true);
    setFormError(null);
    try {
      if (editingUser) {
        const payload = { ...form };
        if (!payload.password) delete payload.password;
        await adminAPI.users.update(editingUser.id, payload);
      } else {
        await adminAPI.users.create(form);
      }
      setShowModal(false);
      refresh();
    } catch (err) {
      console.error('Submit error:', err);
      if (err.response?.data) {
        const data = err.response.data;
        if (typeof data === 'string') {
          setFormError(data);
        } else {
          const lines = [];
          for (const [field, msgs] of Object.entries(data)) {
            const msgsArr = Array.isArray(msgs) ? msgs : [msgs];
            msgsArr.forEach(m => lines.push(`${field}: ${m}`));
          }
          setFormError(lines.join('\n') || 'Validation error. Check your input.');
        }
      } else if (err.message) {
        setFormError(`Network error: ${err.message}`);
      } else {
        setFormError('An unexpected error occurred. Check the console for details.');
      }
    } finally {
      setFormLoading(false);
    }
  };

  const confirmDelete = async () => {
    if (!deleteTarget) return;
    try {
      await adminAPI.users.delete(deleteTarget.id);
      setDeleteTarget(null);
      refresh();
    } catch {
      alert('Failed to delete user');
    }
  };

  const toggleActive = async (user) => {
    const action = user.is_active ? 'deactivate' : 'activate';
    if (!window.confirm(`Are you sure you want to ${action} user "${user.username}"?`)) return;
    try {
      await adminAPI.users.update(user.id, { is_active: !user.is_active });
      refresh();
    } catch {
      alert('Failed to update user status');
    }
  };

  return (
    <div>
      <div className="page-header d-flex justify-content-between align-items-center flex-wrap gap-2">
        <div>
          <h4 className="mb-1">Users Management</h4>
          <p className="mb-0">Add, edit, and manage all system users.</p>
        </div>
        <div className="d-flex align-items-center gap-2">
          <span className="text-muted small">
            <i className="bi bi-arrow-clockwise me-1"></i>
            {updatedLabel ? `Updated ${updatedLabel}` : 'Loading…'}
          </span>
          <button type="button" className="btn btn-sm btn-outline-secondary" onClick={refresh} disabled={loading} title="Refresh now">
            <i className="bi bi-arrow-repeat"></i>
          </button>
          <ExportCsvButton fetcher={adminAPI.exports.users} filename="users.csv" />
          <button className="btn d-flex align-items-center gap-2 px-4" style={{ background: '#6366f1', color: '#fff', borderRadius: '10px', border: 'none' }} onClick={openAdd}>
            <i className="bi bi-plus-lg"></i> Add User
          </button>
        </div>
      </div>

      <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
        <div className="card-body p-4">
          <div className="row mb-3">
            <div className="col-md-6">
              <div className="input-group" style={{ borderRadius: '10px', overflow: 'hidden' }}>
                <span className="input-group-text bg-white border-end-0"><i className="bi bi-search text-muted"></i></span>
                <input
                  type="text" className="form-control border-start-0" placeholder="Search by username, phone, or email..."
                  value={search} onChange={(e) => setSearch(e.target.value)}
                  style={{ padding: '10px 15px' }}
                />
              </div>
            </div>
            <div className="col-md-3">
              <select className="form-select" value={roleFilter} onChange={(e) => setRoleFilter(e.target.value)} style={{ padding: '10px 15px', borderRadius: '10px' }}>
                <option value="">All Roles</option>
                <option value="admin">Admin</option>
                <option value="worker">Worker</option>
                <option value="client">Client</option>
              </select>
            </div>
            <div className="col-md-3">
              <select className="form-select" value={governorateFilter} onChange={(e) => setGovernorateFilter(e.target.value)} style={{ padding: '10px 15px', borderRadius: '10px' }}>
                <option value="">All Governorates</option>
                {governorates.map((g) => (
                  <option key={g.code} value={g.code}>{g.name_en} — {g.name_ar}</option>
                ))}
              </select>
            </div>
          </div>
          <div className="text-muted small mb-2" style={{ fontSize: '13px' }}>
            Total: {total} users{governorateFilter ? ` · filtered by ${govLabel(governorateFilter)}` : ''}
          </div>

          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead style={{ backgroundColor: '#f8fafc' }}>
                <tr>
                  <th style={{ fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' }}>ID</th>
                  <th style={{ fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' }}>Username</th>
                  <th style={{ fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' }}>Phone</th>
                  <th style={{ fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' }}>Email</th>
                  <th style={{ fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' }}>Role</th>
                  <th style={{ fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' }}>Governorate</th>
                  <th style={{ fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' }}>Status</th>
                  <th style={{ fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' }}>Joined</th>
                  <th style={{ fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {loading && (
                  <tr><td colSpan="9" className="text-center py-5"><div className="spinner-border text-primary" role="status"></div></td></tr>
                )}
                {!loading && users.length === 0 && (
                  <tr><td colSpan="9" className="text-center py-5 text-muted">No users found</td></tr>
                )}
                {!loading && users.map((user) => {
                  const rc = roleColors[user.role] || roleColors.client;
                  return (
                    <tr key={user.id}>
                      <td style={{ fontWeight: '500' }}>#{user.id}</td>
                      <td>
                        <div className="d-flex align-items-center gap-2">
                          <div className="rounded-circle d-flex align-items-center justify-content-center" style={{ width: '32px', height: '32px', backgroundColor: '#6366f115', color: '#6366f1', fontSize: '13px', fontWeight: '600' }}>
                            {user.username?.[0]?.toUpperCase() || '?'}
                          </div>
                          {user.username}
                        </div>
                      </td>
                      <td style={{ color: '#475569' }}>{user.phone || '-'}</td>
                      <td style={{ color: '#475569' }}>{user.email || '-'}</td>
                      <td>
                        <span className="badge rounded-pill px-3 py-2" style={{ backgroundColor: rc.bg, color: rc.color, fontSize: '12px', fontWeight: '500' }}>
                          {user.role}
                        </span>
                      </td>
                      <td style={{ color: '#475569', fontSize: '13px' }}>
                        {user.governorate_label || govLabel(user.governorate) || '-'}
                        {user.city ? <div className="text-muted" style={{ fontSize: '11px' }}>{user.city}</div> : null}
                      </td>
                      <td>
                        <span className={`badge rounded-pill px-3 py-2 ${user.is_active ? 'bg-success' : 'bg-secondary'}`} style={{ fontSize: '12px', fontWeight: '500' }}>
                          {user.is_active ? 'Active' : 'Inactive'}
                        </span>
                      </td>
                      <td style={{ color: '#64748b', fontSize: '14px' }}>{new Date(user.date_joined).toLocaleDateString()}</td>
                      <td>
                        <div className="d-flex gap-1">
                          <button className="btn btn-sm" style={{ color: '#6366f1', background: '#6366f110', borderRadius: '8px' }} onClick={() => openEdit(user)} title="Edit">
                            <i className="bi bi-pencil"></i>
                          </button>
                          <button className="btn btn-sm" style={{ color: user.is_active ? '#f59e0b' : '#10b981', background: user.is_active ? '#f59e0b10' : '#10b98110', borderRadius: '8px' }} onClick={() => toggleActive(user)} title={user.is_active ? 'Deactivate' : 'Activate'}>
                            <i className={`bi ${user.is_active ? 'bi-pause-circle' : 'bi-play-circle'}`}></i>
                          </button>
                          <button className="btn btn-sm" style={{ color: '#ef4444', background: '#ef444410', borderRadius: '8px' }} onClick={() => setDeleteTarget(user)} title="Delete">
                            <i className="bi bi-trash"></i>
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {totalPages > 1 && (
            <div className="d-flex justify-content-center mt-4 gap-2">
              <button className="btn btn-sm px-3" style={{ borderRadius: '8px', border: '1px solid #e2e8f0' }} disabled={page <= 1} onClick={() => setPage(p => p - 1)}>
                <i className="bi bi-chevron-left"></i> Previous
              </button>
              <span className="d-flex align-items-center px-3" style={{ fontSize: '14px', color: '#475569' }}>
                Page {page} of {totalPages}
              </span>
              <button className="btn btn-sm px-3" style={{ borderRadius: '8px', border: '1px solid #e2e8f0' }} disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}>
                Next <i className="bi bi-chevron-right"></i>
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Add/Edit Modal */}
      {showModal && (
        <div className="modal d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content" style={{ borderRadius: '15px', border: 'none' }}>
              <div className="modal-header border-0">
                <h5 className="modal-title fw-bold">{editingUser ? 'Edit User' : 'Add New User'}</h5>
                <button type="button" className="btn-close" onClick={() => setShowModal(false)}></button>
              </div>
              <form onSubmit={handleSubmit}>
                <div className="modal-body pt-0">
                  {formError && (
                    <div className="alert alert-danger py-2 px-3" style={{ borderRadius: '10px', fontSize: '13px', border: 'none' }}>
                      <i className="bi bi-exclamation-circle me-1"></i>
                      {formError.split('\n').map((line, i) => <div key={i}>{line}</div>)}
                    </div>
                  )}
                  <div className="mb-3">
                    <label className="form-label" style={{ fontSize: '13px', fontWeight: '500' }}>Username *</label>
                    <input className="form-control" required value={form.username} onChange={(e) => setForm({...form, username: e.target.value})} style={{ borderRadius: '10px', padding: '10px 14px' }} />
                  </div>
                  <div className="row mb-3">
                    <div className="col-md-6">
                      <label className="form-label" style={{ fontSize: '13px', fontWeight: '500' }}>Phone *</label>
                      <input className="form-control" required value={form.phone} onChange={(e) => setForm({...form, phone: e.target.value})} style={{ borderRadius: '10px', padding: '10px 14px' }} />
                    </div>
                    <div className="col-md-6">
                      <label className="form-label" style={{ fontSize: '13px', fontWeight: '500' }}>Email</label>
                      <input className="form-control" type="email" value={form.email} onChange={(e) => setForm({...form, email: e.target.value})} style={{ borderRadius: '10px', padding: '10px 14px' }} />
                    </div>
                  </div>
                  <div className="mb-3">
                    <label className="form-label" style={{ fontSize: '13px', fontWeight: '500' }}>{editingUser ? 'Password (leave blank to keep current)' : 'Password *'}</label>
                    <input className="form-control" type="password" required={!editingUser} value={form.password} onChange={(e) => setForm({...form, password: e.target.value})} style={{ borderRadius: '10px', padding: '10px 14px' }} />
                  </div>
                  <div className="row mb-3">
                    <div className="col-md-6">
                      <label className="form-label" style={{ fontSize: '13px', fontWeight: '500' }}>Role</label>
                      <select className="form-select" value={form.role} onChange={(e) => setForm({...form, role: e.target.value})} style={{ borderRadius: '10px', padding: '10px 14px' }}>
                        <option value="client">Client</option>
                        <option value="worker">Worker</option>
                        <option value="admin">Admin</option>
                      </select>
                    </div>
                    <div className="col-md-6">
                      <label className="form-label" style={{ fontSize: '13px', fontWeight: '500' }}>Active</label>
                      <select className="form-select" value={form.is_active} onChange={(e) => setForm({...form, is_active: e.target.value === 'true'})} style={{ borderRadius: '10px', padding: '10px 14px' }}>
                        <option value="true">Active</option>
                        <option value="false">Inactive</option>
                      </select>
                    </div>
                  </div>
                  <div className="row mb-3">
                    <div className="col-md-6">
                      <label className="form-label" style={{ fontSize: '13px', fontWeight: '500' }}>Governorate {editingUser ? '' : '*'}</label>
                      <select
                        className="form-select"
                        required={!editingUser}
                        value={form.governorate}
                        onChange={(e) => setForm({...form, governorate: e.target.value})}
                        style={{ borderRadius: '10px', padding: '10px 14px' }}
                      >
                        <option value="">Select governorate…</option>
                        {governorates.map((g) => (
                          <option key={g.code} value={g.code}>{g.name_en} — {g.name_ar}</option>
                        ))}
                      </select>
                    </div>
                    <div className="col-md-6">
                      <label className="form-label" style={{ fontSize: '13px', fontWeight: '500' }}>City / Area</label>
                      <input className="form-control" placeholder="e.g. Nasr City" value={form.city} onChange={(e) => setForm({...form, city: e.target.value})} style={{ borderRadius: '10px', padding: '10px 14px' }} />
                    </div>
                  </div>
                  <div className="mb-3">
                    <label className="form-label" style={{ fontSize: '13px', fontWeight: '500' }}>Street address (optional)</label>
                    <input className="form-control" value={form.address} onChange={(e) => setForm({...form, address: e.target.value})} style={{ borderRadius: '10px', padding: '10px 14px' }} />
                  </div>
                </div>
                <div className="modal-footer border-0 pt-0">
                  <button type="button" className="btn px-4" style={{ borderRadius: '10px', border: '1px solid #e2e8f0', color: '#475569' }} onClick={() => setShowModal(false)}>Cancel</button>
                  <button type="submit" className="btn px-4 text-white" style={{ borderRadius: '10px', background: '#6366f1', border: 'none' }} disabled={formLoading}>
                    {formLoading ? <span className="spinner-border spinner-border-sm me-2"></span> : null}
                    {editingUser ? 'Update' : 'Create'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {deleteTarget && (
        <div className="modal d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered modal-sm">
            <div className="modal-content" style={{ borderRadius: '15px', border: 'none' }}>
              <div className="modal-body text-center p-4">
                <div className="rounded-circle d-flex align-items-center justify-content-center mx-auto mb-3" style={{ width: '64px', height: '64px', backgroundColor: '#ef444420' }}>
                  <i className="bi bi-exclamation-triangle fs-3" style={{ color: '#ef4444' }}></i>
                </div>
                <h5 className="fw-bold mb-2">Delete User</h5>
                <p className="text-muted mb-4">Are you sure you want to delete <strong>{deleteTarget.username}</strong>? This action cannot be undone.</p>
                <div className="d-flex gap-2 justify-content-center">
                  <button className="btn px-4" style={{ borderRadius: '10px', border: '1px solid #e2e8f0', color: '#475569' }} onClick={() => setDeleteTarget(null)}>Cancel</button>
                  <button className="btn px-4 text-white" style={{ borderRadius: '10px', background: '#ef4444', border: 'none' }} onClick={confirmDelete}>Delete</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Users;
