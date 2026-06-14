import React from 'react';

const cards = [
  {
    title: 'Total Users',
    icon: 'bi-people',
    color: '#6366f1',
    bgColor: 'rgba(99, 102, 241, 0.1)',
    key: 'users',
  },
  {
    title: 'Total Workers',
    icon: 'bi-person-badge',
    color: '#f59e0b',
    bgColor: 'rgba(245, 158, 11, 0.1)',
    key: 'workers',
  },
  {
    title: 'Total Orders',
    icon: 'bi-cart-check',
    color: '#10b981',
    bgColor: 'rgba(16, 185, 129, 0.1)',
    key: 'orders',
  },
  {
    title: 'Categories',
    icon: 'bi-grid',
    color: '#ef4444',
    bgColor: 'rgba(239, 68, 68, 0.1)',
    key: 'categories',
  },
];

const StatsCards = ({ stats, loading }) => {
  const getValue = (key) => {
    if (loading) return '...';
    if (stats && stats[key] !== undefined) return stats[key];
    return 'N/A';
  };

  return (
    <div className="row g-4">
      {cards.map((card) => (
        <div key={card.key} className="col-xl-3 col-md-6">
          <div
            className="card border-0 shadow-sm h-100"
            style={{ borderRadius: '15px' }}
          >
            <div className="card-body p-4">
              <div className="d-flex align-items-center">
                <div
                  className="d-flex align-items-center justify-content-center rounded-3 me-3"
                  style={{
                    width: '54px',
                    height: '54px',
                    backgroundColor: card.bgColor,
                  }}
                >
                  <i className={`bi ${card.icon} fs-4`} style={{ color: card.color }}></i>
                </div>
                <div>
                  <p className="text-muted mb-0" style={{ fontSize: '13px' }}>{card.title}</p>
                  <h3 className="fw-bold mb-0" style={{ color: '#1e293b' }}>
                    {getValue(card.key)}
                  </h3>
                </div>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default StatsCards;
