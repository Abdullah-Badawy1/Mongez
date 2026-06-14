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

  console.log('[ProtectedRoute] Path:', location.pathname, {
    hasUserInState: !!user,
    hasTokenInStorage: !!storedToken,
    hasUserInStorage: !!storedUser,
    isAuthenticated,
    requiredRole,
    effectiveRole: effectiveUser?.role,
  });

  if (loading || initialLoading) {
    console.log('[ProtectedRoute] Still loading...');
    return (
      <div className="d-flex justify-content-center align-items-center" style={{ height: '100vh' }}>
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    console.log('[ProtectedRoute] Not authenticated, redirecting to /login');
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (requiredRole) {
    const userRole = effectiveUser?.role;
    console.log('[ProtectedRoute] Role check:', { userRole, requiredRole });
    if (userRole !== requiredRole) {
      console.log('[ProtectedRoute] Wrong role, redirecting to /unauthorized');
      return <Navigate to="/unauthorized" replace />;
    }
  }

  console.log('[ProtectedRoute] Access granted to:', location.pathname);
  return children;
};

export default ProtectedRoute;
