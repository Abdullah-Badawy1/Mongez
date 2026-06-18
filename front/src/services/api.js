import axios from 'axios';

const API_BASE = '/api';

let isRefreshing = false;
let failedQueue = [];

const processQueue = (error, token = null) => {
  failedQueue.forEach((prom) => {
    if (error) {
      prom.reject(error);
    } else {
      prom.resolve(token);
    }
  });
  failedQueue = [];
};

const api = axios.create({
  baseURL: API_BASE,
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        }).then((token) => {
          originalRequest.headers.Authorization = `Bearer ${token}`;
          return api(originalRequest);
        }).catch((err) => Promise.reject(err));
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        const refreshToken = localStorage.getItem('refreshToken');
        if (!refreshToken) throw new Error('No refresh token');

        const { data } = await axios.post(`${API_BASE}/auth/token/refresh/`, {
          refresh: refreshToken,
        });

        localStorage.setItem('accessToken', data.access);
        if (data.refresh) {
          localStorage.setItem('refreshToken', data.refresh);
        }
        processQueue(null, data.access);
        originalRequest.headers.Authorization = `Bearer ${data.access}`;
        return api(originalRequest);
      } catch (err) {
        processQueue(err, null);
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        localStorage.removeItem('user');
        window.location.href = '/login';
        return Promise.reject(error);
      } finally {
        isRefreshing = false;
      }
    }

    return Promise.reject(error);
  }
);

export const authAPI = {
  login: (username, password) =>
    api.post('/auth/login/', { username, password }),
  register: (data) => api.post('/auth/register/', data),
  refreshToken: (refresh) =>
    api.post('/auth/token/refresh/', { refresh }),
  getProfile: () => api.get('/users/me/'),
  updateProfile: (data) => api.patch('/users/me/', data),
};

export const categoriesAPI = {
  list: () => api.get('/categories/'),
  create: (data) => api.post('/categories/create/', data),
};

// Static reference list shared with the mobile. Cached in-memory by
// listGovernorates() below so the dropdown doesn't re-fetch on every
// modal open.
let _govCache = null;
export const referenceAPI = {
  listGovernorates: async () => {
    if (_govCache) return _govCache;
    const res = await api.get('/governorates/');
    _govCache = res.data;
    return _govCache;
  },
};

export const workersAPI = {
  list: (params) => api.get('/workers/', { params }),
  detail: (id) => api.get(`/workers/${id}/`),
  create: (data) => api.post('/workers/create/', data),
  myProfile: () => api.get('/workers/me/'),
  updateMyProfile: (data) => api.patch('/workers/me/', data),
  myRatings: () => api.get('/workers/my-ratings/'),
  ratings: (id) => api.get(`/workers/${id}/ratings/`),
};

export const ordersAPI = {
  list: (params) => api.get('/orders/', { params }),
  create: (data) => api.post('/orders/', data),
  detail: (id) => api.get(`/orders/${id}/`),
  accept: (id) => api.post(`/orders/${id}/accept/`),
  reject: (id) => api.post(`/orders/${id}/reject/`),
  cancel: (id) => api.post(`/orders/${id}/cancel/`),
  markFinished: (id) => api.post(`/orders/${id}/mark-finished/`),
  confirmCompletion: (id) => api.post(`/orders/${id}/confirm-completion/`),
};

export const ratingsAPI = {
  create: (data) => api.post('/ratings/', data),
};

export const favoritesAPI = {
  list: () => api.get('/favorites/'),
  add: (workerId) => api.post('/favorites/', { worker_id: workerId }),
  remove: (id) => api.delete(`/favorites/${id}/`),
};

export const notificationsAPI = {
  list: () => api.get('/notifications/'),
  markRead: (id) => api.post(`/notifications/${id}/read/`),
  markAllRead: () => api.post('/notifications/read-all/'),
};

export const adminAPI = {
  dashboard: () => api.get('/admin/dashboard/'),
  users: {
    list: (params) => api.get('/admin/users/', { params }),
    create: (data) => api.post('/admin/users/create/', data),
    detail: (id) => api.get(`/admin/users/${id}/`),
    update: (id, data) => api.patch(`/admin/users/${id}/`, data),
    delete: (id) => api.delete(`/admin/users/${id}/`),
  },
  categories: {
    update: (id, data) => api.patch(`/admin/categories/${id}/`, data),
    delete: (id) => api.delete(`/admin/categories/${id}/`),
  },
  payments: {
    list: () => api.get('/admin/payments/'),
  },
  orders: {
    updateStatus: (id, status) => api.patch(`/admin/orders/${id}/status/`, { status }),
  },
  ratings: {
    list: () => api.get('/admin/ratings/'),
  },
  workers: {
    list: (params) => api.get('/admin/workers/', { params }),
    detail: (id) => api.get(`/admin/workers/${id}/`),
    update: (id, data) => api.patch(`/admin/workers/${id}/`, data),
  },
  exports: {
    orders: () => api.get('/admin/export/orders.csv', { responseType: 'blob' }),
    workers: () => api.get('/admin/export/workers.csv', { responseType: 'blob' }),
    users: () => api.get('/admin/export/users.csv', { responseType: 'blob' }),
    payments: () => api.get('/admin/export/payments.csv', { responseType: 'blob' }),
    categories: () => api.get('/admin/export/categories.csv', { responseType: 'blob' }),
  },
};

export default api;
