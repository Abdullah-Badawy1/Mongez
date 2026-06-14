import React, { useState } from 'react';
import { useNavigate, useLocation, Link } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import logo from '../../assets/images/a.png';

const LoginPage = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const { login, loading: authLoading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const from = location.state?.from?.pathname || '/admin';

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (!username.trim() || !password.trim()) {
      setError('Please enter username and password');
      return;
    }

    const result = await login(username, password);

    if (result.success) {
      navigate(from, { replace: true });
    } else {
      setError(result.message);
    }
  };

  return (
    <div
      className="container-fluid vh-100 d-flex justify-content-center align-items-center"
      style={{
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
      }}
    >
      <div className="card shadow-lg p-4" style={{ maxWidth: '450px', width: '100%', borderRadius: '15px', border: 'none' }}>
        <div className="text-center mb-4">
          <img
            src={logo}
            alt="Mongez Logo"
            style={{ width: '90px', height: '90px', objectFit: 'contain' }}
            className="mb-3"
          />
          <h3 className="fw-bold" style={{ color: '#2c3e50' }}>منجز</h3>
          <p className="text-muted mb-0" style={{ fontSize: '14px' }}>
            Mongez Admin Dashboard
          </p>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="mb-3">
            <label className="form-label fw-semibold" style={{ color: '#555' }}>Username</label>
            <input
              type="text"
              className="form-control form-control-lg"
              placeholder="Enter username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              disabled={authLoading}
              style={{ borderRadius: '10px', border: '1px solid #ddd' }}
            />
          </div>

          <div className="mb-3">
            <label className="form-label fw-semibold" style={{ color: '#555' }}>Password</label>
            <input
              type="password"
              className="form-control form-control-lg"
              placeholder="Enter password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={authLoading}
              style={{ borderRadius: '10px', border: '1px solid #ddd' }}
            />
          </div>

          {error && (
            <div className="alert alert-danger py-2 text-center" style={{ borderRadius: '10px' }}>
              <i className="bi bi-exclamation-circle me-2"></i>
              {error}
            </div>
          )}

          <button
            type="submit"
            className="btn w-100 text-white fw-semibold btn-lg"
            disabled={authLoading}
            style={{
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              border: 'none',
              borderRadius: '10px',
              padding: '12px',
            }}
          >
            {authLoading ? (
              <>
                <span className="spinner-border spinner-border-sm me-2"></span>
                Logging in...
              </>
            ) : (
              'Login to Dashboard'
            )}
          </button>
        </form>

        <hr className="my-3" />

        <div className="text-center">
          <Link to="/" className="text-decoration-none" style={{ color: '#667eea', fontSize: '14px' }}>
            <i className="bi bi-arrow-left me-1"></i>
            Back to Homepage
          </Link>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
