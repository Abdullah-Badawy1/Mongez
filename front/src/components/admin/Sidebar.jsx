import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../../context/AuthContext';
import logo from '../../assets/images/a.png';

const menuItems = [
  { path: '/admin', label: 'Dashboard', icon: 'bi-speedometer2', end: true },
  { path: '/admin/users', label: 'Users', icon: 'bi-people' },
  { path: '/admin/workers', label: 'Workers', icon: 'bi-person-badge' },
  { path: '/admin/categories', label: 'Categories', icon: 'bi-grid' },
  { path: '/admin/orders', label: 'Orders', icon: 'bi-cart-check' },
  { path: '/admin/ratings', label: 'Ratings', icon: 'bi-star' },
  { path: '/admin/payments', label: 'Payments', icon: 'bi-credit-card' },
];

const Sidebar = ({ isRtl }) => {
  const { user } = useAuth();
  const { t } = useTranslation();
  const navigate = useNavigate();

  const sidebarStyle = isRtl
    ? { right: 0, left: 'auto', borderLeft: '1px solid rgba(255,255,255,0.1)' }
    : { left: 0, right: 'auto', borderRight: '1px solid rgba(255,255,255,0.1)' };

  return (
    <div
      className="d-flex flex-column"
      style={{
        width: '260px',
        height: '100vh',
        background: 'linear-gradient(180deg, #1e293b 0%, #0f172a 100%)',
        position: 'fixed',
        top: 0,
        zIndex: 1040,
        overflowY: 'auto',
        ...sidebarStyle,
      }}
    >
      <div
        className="d-flex align-items-center justify-content-center py-4 border-bottom"
        style={{ borderColor: 'rgba(255,255,255,0.1)', cursor: 'pointer' }}
        onClick={() => navigate('/admin')}
      >
        <img
          src={logo}
          alt="Mongez"
          style={{ width: '40px', height: '40px', objectFit: 'contain' }}
          className="me-2"
        />
        <span className="fw-bold fs-4 text-white">منجز</span>
      </div>

      <div className="px-3 mt-3">
        <p className="text-uppercase small text-white-50 mb-2 px-3" style={{ fontSize: '11px', letterSpacing: '1px' }}>
          {t('nav_main_menu') || 'Main Menu'}
        </p>
        <nav className="nav flex-column">
          {menuItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              end={item.end}
              className={({ isActive }) =>
                `nav-link d-flex align-items-center px-3 py-2.5 mb-1 rounded-3 ${
                  isActive ? 'text-white' : 'text-white-50'
                }`
              }
              style={({ isActive }) => ({
                backgroundColor: isActive ? 'rgba(99, 102, 241, 0.15)' : 'transparent',
                borderLeft: isActive && !isRtl ? '3px solid #6366f1' : 'transparent',
                borderRight: isActive && isRtl ? '3px solid #6366f1' : 'transparent',
                transition: 'all 0.2s ease',
                fontSize: '14px',
                fontWeight: isActive ? '600' : '400',
              })}
            >
              <i className={`bi ${item.icon} me-3 fs-5`}></i>
              {item.label}
            </NavLink>
          ))}
        </nav>
      </div>

      <div className="mt-auto p-3 border-top" style={{ borderColor: 'rgba(255,255,255,0.1)' }}>
        <div className="d-flex align-items-center px-3">
          <div
            className="d-flex align-items-center justify-content-center rounded-circle me-2"
            style={{
              width: '36px',
              height: '36px',
              background: 'linear-gradient(135deg, #667eea, #764ba2)',
              fontSize: '14px',
              fontWeight: '600',
              color: '#fff',
              flexShrink: 0,
            }}
          >
            {user?.username?.charAt(0).toUpperCase() || 'A'}
          </div>
          <div className="text-white" style={{ fontSize: '13px' }}>
            <div className="fw-semibold" style={{ lineHeight: 1.2 }}>{user?.username || 'Admin'}</div>
            <small className="text-white-50">{user?.role || 'admin'}</small>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Sidebar;
