import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from '../context/AuthContext';
import ProtectedRoute from './ProtectedRoute';
import PublicRoute from './PublicRoute';
import LandingPage from '../pages/LandingPage';
import LoginPage from '../pages/Login';
import NotFound from '../pages/NotFound';
import Layout from '../components/layout/Layout';
import AdminLayout from '../components/admin/AdminLayout';
import Dashboard from '../pages/admin/Dashboard';
import Users from '../pages/admin/Users';
import Workers from '../pages/admin/Workers';
import Categories from '../pages/admin/Categories';
import Orders from '../pages/admin/Orders';
import Ratings from '../pages/admin/Ratings';
import Payments from '../pages/admin/Payments';

function AppRoutes() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route element={<Layout />}>
            <Route path="/" element={<LandingPage />} />
          </Route>

          <Route
            path="/login"
            element={
              <PublicRoute>
                <LoginPage />
              </PublicRoute>
            }
          />

          <Route
            path="/admin"
            element={
              <ProtectedRoute requiredRole="admin">
                <AdminLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Dashboard />} />
            <Route path="users" element={<Users />} />
            <Route path="workers" element={<Workers />} />
            <Route path="categories" element={<Categories />} />
            <Route path="orders" element={<Orders />} />
            <Route path="ratings" element={<Ratings />} />
            <Route path="payments" element={<Payments />} />
          </Route>

          <Route path="/unauthorized" element={
            <div className="container-fluid vh-100 d-flex justify-content-center align-items-center" style={{ backgroundColor: '#f1f5f9' }}>
              <div className="text-center">
                <h1 className="display-3 fw-bold" style={{ color: '#ef4444' }}>403</h1>
                <h4 className="fw-bold mb-2" style={{ color: '#1e293b' }}>Unauthorized Access</h4>
                <p className="text-muted mb-4">You do not have permission to access this page.</p>
                <a href="/" className="btn text-white px-4 py-2" style={{ background: '#6366f1', border: 'none', borderRadius: '10px' }}>
                  <i className="bi bi-house-door me-2"></i>
                  Back to Home
                </a>
              </div>
            </div>
          } />

          <Route path="*" element={<NotFound />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default AppRoutes;
