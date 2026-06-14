import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const ProtectedRoute = ({ children, requiredRole }) => {
  const { user, loading, initialLoading } = useAuth();
  const location = useLocation();

  const storedToken = localStorage.getItem('accessToken');
  let storedUser = null;
  try {
    const raw = localStorage.getItem('user');
    if (raw) storedUser = JSON.parse(raw);
  } catch {
    /* ignore */
  }

  const isAuthenticated = !!user || !!storedToken;
  const effectiveUser = user || storedUser;

  if (loading || initialLoading) {
    return (
      <div className="d-flex justify-content-center align-items-center" style={{ height: '100vh' }}>
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (requiredRole) {
    const userRole = effectiveUser?.role;
    if (userRole !== requiredRole) {
      return <Navigate to="/unauthorized" replace />;
    }
  }

  return children;
};

export default ProtectedRoute;
