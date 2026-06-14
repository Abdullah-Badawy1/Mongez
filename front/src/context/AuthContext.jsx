import React, { createContext, useState, useContext, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { authAPI } from '../services/api';

const AuthContext = createContext();

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
    console.log('[AuthContext] Initializing - checking localStorage...');
    const savedUser = localStorage.getItem('user');
    const token = localStorage.getItem('accessToken');
    console.log('[AuthContext] Initial check:', { hasSavedUser: !!savedUser, hasToken: !!token });

    if (savedUser && token) {
      try {
        const parsed = JSON.parse(savedUser);
        setUser(parsed);
        console.log('[AuthContext] Restored user from localStorage:', parsed.username, parsed.role);
      } catch (e) {
        console.warn('[AuthContext] Failed to parse saved user, clearing storage:', e);
        localStorage.removeItem('user');
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
      }
    } else {
      console.log('[AuthContext] No saved session found');
    }
    setInitialLoading(false);
  }, []);

  const login = useCallback(async (username, password) => {
    console.log('[AuthContext] Login started for:', username);
    setLoading(true);
    try {
      console.log('[AuthContext] Calling authAPI.login...');
      const response = await authAPI.login(username, password);
      console.log('[AuthContext] Login API response:', response.status, response.data);

      const { user: userData, tokens } = response.data;

      if (!tokens || !tokens.access) {
        console.error('[AuthContext] No access token in response!');
        return { success: false, message: 'Invalid server response: missing token.' };
      }

      console.log('[AuthContext] Saving tokens to localStorage...');
      localStorage.setItem('accessToken', tokens.access);
      localStorage.setItem('refreshToken', tokens.refresh);
      localStorage.setItem('user', JSON.stringify(userData));
      console.log('[AuthContext] User data saved:', userData.username, 'role:', userData.role);

      setUser(userData);

      const verify = localStorage.getItem('accessToken');
      console.log('[AuthContext] Verified localStorage token:', !!verify);

      return { success: true, user: userData };
    } catch (err) {
      console.error('[AuthContext] Login error:', err.message);
      if (err.response) {
        console.error('[AuthContext] Response data:', err.response.data);
        console.error('[AuthContext] Response status:', err.response.status);
      }

      const message =
        err.response?.data?.detail ||
        err.response?.data?.message ||
        (err.code === 'ERR_NETWORK'
          ? 'Cannot connect to server. Make sure Django backend is running.'
          : 'Login failed. Please check your credentials.');
      return { success: false, message };
    } finally {
      setLoading(false);
      console.log('[AuthContext] Login finished, loading set to false');
    }
  }, []);

  const logout = useCallback(() => {
    console.log('[AuthContext] Logging out...');
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
