import React from 'react';
import { useAuth } from '../../context/AuthContext';
import logo from '../../assets/images/a.png';

const Topbar = ({ toggleSidebar }) => {
  const { user, logout } = useAuth();

  return (
    <nav
      className="navbar navbar-expand px-4 py-3 shadow-sm"
      style={{
        backgroundColor: '#fff',
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        zIndex: 1030,
        height: '64px',
      }}
    >
      <div className="d-flex align-items-center w-100">
        <button
          className="btn btn-link text-dark p-0 me-3 d-lg-none"
          onClick={toggleSidebar}
          style={{ textDecoration: 'none' }}
        >
          <i className="bi bi-list fs-4"></i>
        </button>

        <div className="d-flex align-items-center d-lg-none">
          <img
            src={logo}
            alt="Mongez"
            style={{ width: '28px', height: '28px', objectFit: 'contain' }}
            className="me-2"
          />
          <span className="fw-bold" style={{ color: '#2c3e50' }}>منجز</span>
        </div>

        <div className="ms-auto d-flex align-items-center gap-3">
          <div className="d-none d-md-flex align-items-center gap-2 px-3 py-1 rounded-pill" style={{ backgroundColor: '#f1f5f9' }}>
            <i className="bi bi-person-circle text-muted"></i>
            <span className="text-muted" style={{ fontSize: '14px' }}>
              {user?.username || 'Admin'}
            </span>
            <span
              className="badge rounded-pill"
              style={{
                fontSize: '10px',
                background: 'linear-gradient(135deg, #667eea, #764ba2)',
              }}
            >
              {user?.role || 'admin'}
            </span>
          </div>

          <button
            className="btn btn-link text-decoration-none text-muted p-0 position-relative"
            title="Notifications"
          >
            <i className="bi bi-bell fs-5"></i>
            <span
              className="position-absolute top-0 start-100 translate-middle badge rounded-pill"
              style={{
                fontSize: '9px',
                background: 'linear-gradient(135deg, #ff6b6b, #ee5a52)',
                padding: '2px 5px',
              }}
            >
              0
            </span>
          </button>

          <button
            className="btn btn-link text-decoration-none text-muted p-0"
            title="Logout"
            onClick={logout}
          >
            <i className="bi bi-box-arrow-right fs-5" style={{ color: '#ef4444' }}></i>
          </button>
        </div>
      </div>
    </nav>
  );
};

export default Topbar;
