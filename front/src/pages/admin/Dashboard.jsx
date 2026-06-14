import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import StatsCards from '../../components/admin/StatsCards';
import { adminAPI } from '../../services/api';

const quickLinks = [
  { path: '/admin/users', label: 'Manage Users', icon: 'bi-people', color: '#6366f1', desc: 'View and manage all system users' },
  { path: '/admin/workers', label: 'Manage Workers', icon: 'bi-person-badge', color: '#f59e0b', desc: 'View all registered workers' },
  { path: '/admin/categories', label: 'Manage Categories', icon: 'bi-grid', color: '#10b981', desc: 'Manage service categories' },
  { path: '/admin/orders', label: 'Manage Orders', icon: 'bi-cart-check', color: '#ef4444', desc: 'Track and manage all orders' },
  { path: '/admin/ratings', label: 'Ratings & Reviews', icon: 'bi-star', color: '#8b5cf6', desc: 'View all ratings and reviews' },
  { path: '/admin/payments', label: 'Payments', icon: 'bi-credit-card', color: '#ec4899', desc: 'Monitor payment transactions' },
];

const statusColors = {
  PENDING: '#f59e0b',
  ACCEPTED: '#3b82f6',
  IN_PROGRESS: '#8b5cf6',
  WAITING_CONFIRMATION: '#f97316',
  REJECTED: '#ef4444',
  CANCELLED: '#6b7280',
  COMPLETED: '#10b981',
};

const Dashboard = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [recentOrders, setRecentOrders] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const res = await adminAPI.dashboard();
        const data = res.data;
        setStats(data.stats);
        setRecentOrders(data.recent_orders || []);
      } catch {
        setStats(null);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  const statCards = stats ? {
    users: stats.total_users,
    workers: stats.total_workers,
    orders: stats.total_orders,
    categories: stats.total_categories,
    clients: stats.total_clients,
    revenue: stats.total_revenue,
    payments: stats.total_payments,
    orders_by_status: stats.orders_by_status,
  } : null;

  return (
    <div>
      <div className="page-header">
        <h4 className="mb-1">Dashboard</h4>
        <p className="mb-0">Welcome back! Here is an overview of your system.</p>
      </div>

      <StatsCards stats={statCards} loading={loading} />

      <div className="row g-4 mt-2">
        <div className="col-lg-8">
          <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
            <div className="card-header bg-white border-0 py-3 px-4 d-flex justify-content-between align-items-center">
              <h6 className="fw-bold mb-0" style={{ color: '#1e293b' }}>Recent Orders</h6>
              <Link to="/admin/orders" className="text-decoration-none" style={{ fontSize: '13px', color: '#6366f1' }}>
                View All <i className="bi bi-arrow-right ms-1"></i>
              </Link>
            </div>
            <div className="card-body px-4 pb-4 pt-0">
              {recentOrders.length === 0 && !loading && (
                <p className="text-muted text-center py-4 mb-0">No orders yet</p>
              )}
              {recentOrders.map((order) => (
                <div key={order.id} className="d-flex align-items-center justify-content-between py-3 border-bottom" style={{ borderColor: '#f1f5f9 !important' }}>
                  <div>
                    <p className="fw-semibold mb-1" style={{ fontSize: '14px', color: '#1e293b' }}>
                      Order #{order.id} - {order.service_category?.name || 'N/A'}
                    </p>
                    <small className="text-muted">
                      {order.client?.username || 'Unknown'} | {new Date(order.created_at).toLocaleDateString()}
                    </small>
                  </div>
                  <span
                    className="badge rounded-pill px-3 py-2"
                    style={{
                      backgroundColor: `${statusColors[order.status] || '#6b7280'}20`,
                      color: statusColors[order.status] || '#6b7280',
                      fontSize: '12px',
                      fontWeight: '500',
                    }}
                  >
                    {order.status?.replace('_', ' ')}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="col-lg-4">
          <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
            <div className="card-header bg-white border-0 py-3 px-4">
              <h6 className="fw-bold mb-0" style={{ color: '#1e293b' }}>Quick Actions</h6>
            </div>
            <div className="card-body px-4 pb-4 pt-0">
              <Link
                to="/admin/users"
                className="btn w-100 d-flex align-items-center justify-content-center gap-2 mb-2"
                style={{
                  background: 'linear-gradient(135deg, #667eea, #764ba2)',
                  color: '#fff',
                  border: 'none',
                  borderRadius: '10px',
                  padding: '10px',
                }}
              >
                <i className="bi bi-people"></i>
                Manage Users
              </Link>

              <Link
                to="/admin/categories"
                className="btn w-100 d-flex align-items-center justify-content-center gap-2 mb-2"
                style={{
                  background: 'linear-gradient(135deg, #10b981, #059669)',
                  color: '#fff',
                  border: 'none',
                  borderRadius: '10px',
                  padding: '10px',
                }}
              >
                <i className="bi bi-grid"></i>
                Manage Categories
              </Link>

              <Link
                to="/admin/orders"
                className="btn btn-outline-secondary w-100 d-flex align-items-center justify-content-center gap-2"
                style={{ borderRadius: '10px', borderColor: '#e2e8f0', color: '#475569' }}
              >
                <i className="bi bi-eye"></i>
                View All Orders
              </Link>
            </div>
          </div>
        </div>
      </div>

      <div className="row g-4 mt-1">
        {quickLinks.map((link) => (
          <div key={link.path} className="col-xl-4 col-md-6">
            <Link to={link.path} className="admin-link-card">
              <div className="card border-0 shadow-sm h-100" style={{ borderRadius: '15px' }}>
                <div className="card-body p-4 d-flex align-items-center">
                  <div
                    className="d-flex align-items-center justify-content-center rounded-3 me-3"
                    style={{
                      width: '50px',
                      height: '50px',
                      backgroundColor: `${link.color}15`,
                      flexShrink: 0,
                    }}
                  >
                    <i className={`bi ${link.icon} fs-4`} style={{ color: link.color }}></i>
                  </div>
                  <div>
                    <h6 className="fw-bold mb-1" style={{ color: '#1e293b', fontSize: '14px' }}>{link.label}</h6>
                    <p className="text-muted mb-0" style={{ fontSize: '12px' }}>{link.desc}</p>
                  </div>
                </div>
              </div>
            </Link>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Dashboard;
