import React, { createContext, useState, useContext, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { authAPI } from '../services/api';

const AuthContext = createContext();

// eslint-disable-next-line react-refresh/only-export-components
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(false);
  const [initialLoading, setInitialLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const savedUser = localStorage.getItem('user');
    const token = localStorage.getItem('accessToken');

    if (savedUser && token) {
      try {
        const parsed = JSON.parse(savedUser);
        setUser(parsed);
      } catch {
        localStorage.removeItem('user');
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
      }
    }
    setInitialLoading(false);
  }, []);

  const login = useCallback(async (username, password) => {
    setLoading(true);
    try {
      const response = await authAPI.login(username, password);

      const { user: userData, tokens } = response.data;

      if (!tokens || !tokens.access) {
        return { success: false, message: 'Invalid server response: missing token.' };
      }

      localStorage.setItem('accessToken', tokens.access);
      localStorage.setItem('refreshToken', tokens.refresh);
      localStorage.setItem('user', JSON.stringify(userData));

      setUser(userData);

      return { success: true, user: userData };
    } catch (err) {
      const message =
        err.response?.data?.detail ||
        err.response?.data?.message ||
        (err.code === 'ERR_NETWORK'
          ? 'Cannot connect to server. Make sure Django backend is running.'
          : 'Login failed. Please check your credentials.');
      return { success: false, message };
    } finally {
      setLoading(false);
    }
  }, []);

  const logout = useCallback(() => {
    setUser(null);
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('user');
    navigate('/login', { replace: true });
  }, [navigate]);

  const hasRole = useCallback((requiredRole) => {
    if (user) return user.role === requiredRole;
    const storedUser = localStorage.getItem('user');
    if (storedUser) {
      try {
        return JSON.parse(storedUser).role === requiredRole;
      } catch {
        return false;
      }
    }
    return false;
  }, [user]);

  const refreshProfile = useCallback(async () => {
    try {
      const response = await authAPI.getProfile();
      const updatedUser = response.data;
      localStorage.setItem('user', JSON.stringify(updatedUser));
      setUser(updatedUser);
      return updatedUser;
    } catch {
      return null;
    }
  }, []);

  const value = {
    user,
    loading,
    initialLoading,
    login,
    logout,
    hasRole,
    isAuthenticated: !!user || !!localStorage.getItem('accessToken'),
    refreshProfile,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
