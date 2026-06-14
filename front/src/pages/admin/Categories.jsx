import React, { useState, useEffect, useCallback } from 'react';
import { categoriesAPI, adminAPI } from '../../services/api';

const Categories = () => {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingCat, setEditingCat] = useState(null);
  const [form, setForm] = useState({ name: '', image: null });
  const [formLoading, setFormLoading] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [formError, setFormError] = useState(null);

  const fetchCategories = useCallback(async () => {
    setLoading(true);
    try {
      const res = await categoriesAPI.list();
      setCategories(res.data || []);
    } catch {
      setCategories([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchCategories(); }, [fetchCategories]);

  const openAdd = () => {
    setEditingCat(null);
    setForm({ name: '', image: null });
    setFormError(null);
    setShowModal(true);
  };

  const openEdit = (cat) => {
    setEditingCat(cat);
    setForm({ name: cat.name, image: null });
    setFormError(null);
    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setFormLoading(true);
    setFormError(null);
    try {
      if (editingCat) {
        const payload = { name: form.name };
        await adminAPI.categories.update(editingCat.id, payload);
      } else {
        const payload = new FormData();
        payload.append('name', form.name);
        if (form.image) payload.append('image', form.image);
        await categoriesAPI.create(payload);
      }
      setShowModal(false);
      fetchCategories();
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
          setFormError(lines.join('\n') || 'Validation error.');
        }
      } else if (err.message) {
        setFormError(`Network error: ${err.message}`);
      } else {
        setFormError('An unexpected error occurred.');
      }
    } finally {
      setFormLoading(false);
    }
  };

  const confirmDelete = async () => {
    if (!deleteTarget) return;
    try {
      await adminAPI.categories.delete(deleteTarget.id);
      setDeleteTarget(null);
      fetchCategories();
    } catch {
      alert('Failed to delete category. Make sure no workers are assigned to it.');
    }
  };

  return (
    <div>
      <div className="page-header d-flex justify-content-between align-items-center">
        <div>
          <h4 className="mb-1">Categories Management</h4>
          <p className="mb-0">Manage service categories for workers.</p>
        </div>
        <button className="btn d-flex align-items-center gap-2 px-4" style={{ background: '#10b981', color: '#fff', borderRadius: '10px', border: 'none' }} onClick={openAdd}>
          <i className="bi bi-plus-lg"></i> Add Category
        </button>
      </div>

      <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
        <div className="card-body p-4">
          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead style={{ backgroundColor: '#f8fafc' }}>
                <tr>
                  <th style={{ fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' }}>ID</th>
                  <th style={{ fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' }}>Name</th>
                  <th style={{ fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' }}>Image</th>
                  <th style={{ fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {loading && (
                  <tr><td colSpan="4" className="text-center py-5"><div className="spinner-border text-success" role="status"></div></td></tr>
                )}
                {!loading && categories.length === 0 && (
                  <tr><td colSpan="4" className="text-center py-5 text-muted">No categories found</td></tr>
                )}
                {!loading && categories.map((cat) => (
                  <tr key={cat.id}>
                    <td style={{ fontWeight: '500' }}>#{cat.id}</td>
                    <td style={{ fontWeight: '500', color: '#1e293b' }}>{cat.name}</td>
                    <td>
                      {cat.image ? (
                        <img src={cat.image} alt={cat.name} style={{ width: '48px', height: '48px', borderRadius: '8px', objectFit: 'cover' }} />
                      ) : (
                        <span className="text-muted">-</span>
                      )}
                    </td>
                    <td>
                      <div className="d-flex gap-1">
                        <button className="btn btn-sm" style={{ color: '#10b981', background: '#10b98110', borderRadius: '8px' }} onClick={() => openEdit(cat)} title="Edit">
                          <i className="bi bi-pencil"></i>
                        </button>
                        <button className="btn btn-sm" style={{ color: '#ef4444', background: '#ef444410', borderRadius: '8px' }} onClick={() => setDeleteTarget(cat)} title="Delete">
                          <i className="bi bi-trash"></i>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Add/Edit Modal */}
      {showModal && (
        <div className="modal d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content" style={{ borderRadius: '15px', border: 'none' }}>
              <div className="modal-header border-0">
                <h5 className="modal-title fw-bold">{editingCat ? 'Edit Category' : 'Add New Category'}</h5>
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
                    <label className="form-label" style={{ fontSize: '13px', fontWeight: '500' }}>Name *</label>
                    <input className="form-control" required value={form.name} onChange={(e) => setForm({...form, name: e.target.value})} style={{ borderRadius: '10px', padding: '10px 14px' }} />
                  </div>
                  {!editingCat && (
                    <div className="mb-3">
                      <label className="form-label" style={{ fontSize: '13px', fontWeight: '500' }}>Image (optional)</label>
                      <input className="form-control" type="file" accept="image/*" onChange={(e) => setForm({...form, image: e.target.files[0]})} style={{ borderRadius: '10px', padding: '10px 14px' }} />
                    </div>
                  )}
                </div>
                <div className="modal-footer border-0 pt-0">
                  <button type="button" className="btn px-4" style={{ borderRadius: '10px', border: '1px solid #e2e8f0', color: '#475569' }} onClick={() => setShowModal(false)}>Cancel</button>
                  <button type="submit" className="btn px-4 text-white" style={{ borderRadius: '10px', background: '#10b981', border: 'none' }} disabled={formLoading}>
                    {formLoading ? <span className="spinner-border spinner-border-sm me-2"></span> : null}
                    {editingCat ? 'Update' : 'Create'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation */}
      {deleteTarget && (
        <div className="modal d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered modal-sm">
            <div className="modal-content" style={{ borderRadius: '15px', border: 'none' }}>
              <div className="modal-body text-center p-4">
                <div className="rounded-circle d-flex align-items-center justify-content-center mx-auto mb-3" style={{ width: '64px', height: '64px', backgroundColor: '#ef444420' }}>
                  <i className="bi bi-exclamation-triangle fs-3" style={{ color: '#ef4444' }}></i>
                </div>
                <h5 className="fw-bold mb-2">Delete Category</h5>
                <p className="text-muted mb-4">Are you sure you want to delete <strong>{deleteTarget.name}</strong>?</p>
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

export default Categories;
