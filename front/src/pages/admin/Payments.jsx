import React, { useState, useEffect } from 'react';
import { adminAPI } from '../../services/api';
import Table from '../../components/admin/Table';

const paymentColors = {
  AUTHORIZED: { bg: '#3b82f620', color: '#3b82f6' },
  CAPTURED: { bg: '#10b98120', color: '#10b981' },
  VOIDED: { bg: '#6b728020', color: '#6b7280' },
  FAILED: { bg: '#ef444420', color: '#ef4444' },
};

const Payments = () => {
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPayments = async () => {
      try {
        const res = await adminAPI.payments.list();
        setPayments(res.data || []);
      } catch {
        setPayments([]);
      } finally {
        setLoading(false);
      }
    };
    fetchPayments();
  }, []);

  const columns = [
    { key: 'id', label: 'Payment #' },
    { key: 'order_id', label: 'Order ID' },
    {
      key: 'amount',
      label: 'Amount',
      render: (row) => `${parseFloat(row.amount).toFixed(2)} EGP`,
    },
    {
      key: 'payment_status',
      label: 'Status',
      render: (row) => {
        const pc = paymentColors[row.payment_status] || { bg: '#6b728020', color: '#6b7280' };
        return (
          <span className="badge rounded-pill px-3 py-2" style={{ backgroundColor: pc.bg, color: pc.color, fontSize: '12px', fontWeight: '500' }}>
            {row.payment_status}
          </span>
        );
      },
    },
    {
      key: 'paymob_transaction_id',
      label: 'Transaction ID',
      render: (row) => row.paymob_transaction_id || '-',
    },
    {
      key: 'created_at',
      label: 'Date',
      render: (row) => new Date(row.created_at).toLocaleDateString(),
    },
  ];

  const capturedTotal = payments
    .filter((p) => p.payment_status === 'CAPTURED')
    .reduce((sum, p) => sum + parseFloat(p.amount), 0);

  return (
    <div>
      <div className="page-header">
        <h4 className="mb-1">Payments Management</h4>
        <p className="mb-0">Monitor all commission payment transactions.</p>
      </div>

      <div className="row g-4 mb-4">
        <div className="col-md-3">
          <div className="card border-0 shadow-sm" style={{ borderRadius: '12px' }}>
            <div className="card-body p-3 text-center">
              <p className="text-muted mb-1" style={{ fontSize: '12px' }}>Total Payments</p>
              <h4 className="fw-bold mb-0" style={{ color: '#1e293b' }}>{payments.length}</h4>
            </div>
          </div>
        </div>
        <div className="col-md-3">
          <div className="card border-0 shadow-sm" style={{ borderRadius: '12px' }}>
            <div className="card-body p-3 text-center">
              <p className="text-muted mb-1" style={{ fontSize: '12px' }}>Captured</p>
              <h4 className="fw-bold mb-0" style={{ color: '#10b981' }}>{payments.filter((p) => p.payment_status === 'CAPTURED').length}</h4>
            </div>
          </div>
        </div>
        <div className="col-md-3">
          <div className="card border-0 shadow-sm" style={{ borderRadius: '12px' }}>
            <div className="card-body p-3 text-center">
              <p className="text-muted mb-1" style={{ fontSize: '12px' }}>Failed</p>
              <h4 className="fw-bold mb-0" style={{ color: '#ef4444' }}>{payments.filter((p) => p.payment_status === 'FAILED').length}</h4>
            </div>
          </div>
        </div>
        <div className="col-md-3">
          <div className="card border-0 shadow-sm" style={{ borderRadius: '12px' }}>
            <div className="card-body p-3 text-center">
              <p className="text-muted mb-1" style={{ fontSize: '12px' }}>Revenue</p>
              <h4 className="fw-bold mb-0" style={{ color: '#6366f1' }}>{capturedTotal.toFixed(2)} EGP</h4>
            </div>
          </div>
        </div>
      </div>

      <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
        <div className="card-body p-4">
          <Table columns={columns} data={payments} loading={loading} emptyMessage="No payments found" />
        </div>
      </div>
    </div>
  );
};

export default Payments;
