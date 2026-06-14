import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const PublicRoute = ({ children }) => {
  const { user, loading, initialLoading } = useAuth();
  const location = useLocation();

  const storedToken = localStorage.getItem('accessToken');
  const isAuthenticated = !!user || !!storedToken;

  console.log('[PublicRoute] Path:', location.pathname, {
    hasUserInState: !!user,
    hasTokenInStorage: !!storedToken,
    isAuthenticated,
  });

  if (loading || initialLoading) {
    console.log('[PublicRoute] Still loading...');
    return (
      <div className="d-flex justify-content-center align-items-center" style={{ height: '100vh' }}>
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  if (isAuthenticated) {
    console.log('[PublicRoute] Already authenticated, redirecting to /admin');
    return <Navigate to="/admin" replace />;
  }

  console.log('[PublicRoute] Not authenticated, showing public page');
  return children;
};

export default PublicRoute;
