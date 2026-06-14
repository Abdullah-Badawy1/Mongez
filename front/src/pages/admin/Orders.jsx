import React, { useState, useEffect, useCallback } from 'react';
import { ordersAPI, adminAPI } from '../../services/api';
import Table from '../../components/admin/Table';

const statusColors = {
  PENDING: { bg: '#f59e0b20', color: '#f59e0b' },
  ACCEPTED: { bg: '#3b82f620', color: '#3b82f6' },
  IN_PROGRESS: { bg: '#8b5cf620', color: '#8b5cf6' },
  WAITING_CONFIRMATION: { bg: '#f9731620', color: '#f97316' },
  REJECTED: { bg: '#ef444420', color: '#ef4444' },
  CANCELLED: { bg: '#6b728020', color: '#6b7280' },
  COMPLETED: { bg: '#10b98120', color: '#10b981' },
};

const allStatuses = ['PENDING', 'ACCEPTED', 'IN_PROGRESS', 'WAITING_CONFIRMATION', 'REJECTED', 'CANCELLED', 'COMPLETED'];

const Orders = () => {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [changingStatus, setChangingStatus] = useState(null);

  const fetchOrders = useCallback(async () => {
    setLoading(true);
    try {
      const res = await ordersAPI.list({ page_size: 100 });
      setOrders(res.data?.results || []);
    } catch {
      setOrders([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchOrders(); }, [fetchOrders]);

  const handleStatusChange = async (orderId, newStatus) => {
    setChangingStatus(orderId);
    try {
      await adminAPI.orders.updateStatus(orderId, newStatus);
      fetchOrders();
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to update order status');
    } finally {
      setChangingStatus(null);
    }
  };

  const filteredOrders = statusFilter ? orders.filter((o) => o.status === statusFilter) : orders;

  const columns = [
    { key: 'id', label: 'Order #' },
    {
      key: 'client',
      label: 'Client',
      render: (row) => row.client?.username || 'N/A',
    },
    {
      key: 'worker',
      label: 'Worker',
      render: (row) => row.worker?.username || 'Unassigned',
    },
    {
      key: 'service_category',
      label: 'Service',
      render: (row) => row.service_category?.name || 'N/A',
    },
    {
      key: 'status',
      label: 'Status',
      render: (row) => {
        const colors = statusColors[row.status] || { bg: '#6b728020', color: '#6b7280' };
        return (
          <span className="badge rounded-pill px-3 py-2" style={{ backgroundColor: colors.bg, color: colors.color, fontSize: '12px', fontWeight: '500' }}>
            {row.status?.replace(/_/g, ' ')}
          </span>
        );
      },
    },
    {
      key: 'created_at',
      label: 'Date',
      render: (row) => new Date(row.created_at).toLocaleDateString(),
    },
    {
      key: 'actions',
      label: 'Change Status',
      render: (row) => (
        <select
          className="form-select form-select-sm"
          style={{ borderRadius: '8px', fontSize: '12px', maxWidth: '160px' }}
          value=""
          onChange={(e) => {
            if (e.target.value) handleStatusChange(row.id, e.target.value);
          }}
          disabled={changingStatus === row.id}
        >
          <option value="">{changingStatus === row.id ? 'Updating...' : 'Change to...'}</option>
          {allStatuses.filter((s) => s !== row.status).map((s) => (
            <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>
          ))}
        </select>
      ),
    },
  ];

  return (
    <div>
      <div className="page-header d-flex justify-content-between align-items-center">
        <div>
          <h4 className="mb-1">Orders Management</h4>
          <p className="mb-0">View, filter, and change order statuses.</p>
        </div>
        <div>
          <select className="form-select" value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} style={{ borderRadius: '10px', padding: '8px 14px', minWidth: '180px' }}>
            <option value="">All Statuses</option>
            {allStatuses.map((s) => (
              <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>
            ))}
          </select>
        </div>
      </div>

      <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
        <div className="card-body p-4">
          <div className="mb-3 d-flex gap-3 flex-wrap">
            {allStatuses.map((s) => {
              const colors = statusColors[s] || { color: '#6b7280', bg: '#6b728020' };
              const count = orders.filter((o) => o.status === s).length;
              return (
                <div key={s} className="d-flex align-items-center gap-1" style={{ fontSize: '13px' }}>
                  <span className="badge rounded-pill px-2 py-1" style={{ backgroundColor: colors.bg, color: colors.color }}>{s.replace(/_/g, ' ')}</span>
                  <span className="fw-bold" style={{ color: colors.color }}>{count}</span>
                </div>
              );
            })}
          </div>
          <Table columns={columns} data={filteredOrders} loading={loading} emptyMessage="No orders found" />
        </div>
      </div>
    </div>
  );
};

export default Orders;
