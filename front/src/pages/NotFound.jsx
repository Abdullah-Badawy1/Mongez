import React from 'react';
import { Link } from 'react-router-dom';

const NotFound = () => {
  return (
    <div
      className="container-fluid d-flex justify-content-center align-items-center"
      style={{ minHeight: '100vh', backgroundColor: '#f1f5f9' }}
    >
      <div className="text-center">
        <h1 className="display-1 fw-bold" style={{ color: '#6366f1' }}>404</h1>
        <h4 className="fw-bold mb-2" style={{ color: '#1e293b' }}>Page Not Found</h4>
        <p className="text-muted mb-4">The page you are looking for does not exist or has been moved.</p>
        <Link
          to="/"
          className="btn text-white px-4 py-2"
          style={{
            background: 'linear-gradient(135deg, #667eea, #764ba2)',
            border: 'none',
            borderRadius: '10px',
          }}
        >
          <i className="bi bi-house-door me-2"></i>
          Back to Home
        </Link>
      </div>
    </div>
  );
};

export default NotFound;
