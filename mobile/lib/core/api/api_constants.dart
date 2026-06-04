class ApiConstants {
  // Change to http://10.0.2.2:8000/api/ when running on Android emulator.
  static const String baseUrl = 'http://localhost:8000/api/';

  // Auth
  static const String register = 'auth/register/';
  static const String login = 'auth/login/';
  static const String logout = 'auth/logout/';
  static const String passwordChange = 'auth/password/';
  static const String tokenRefresh = 'auth/token/refresh/';

  // Users
  static const String me = 'users/me/';

  // Workers / categories
  static const String categories = 'categories/';
  static const String workers = 'workers/';
  static const String workersMe = 'workers/me/';
  static const String workersCreate = 'workers/create/';
  static String workerStats(int id) => 'workers/$id/stats/';
  static String workerRatings(int userId) => 'ratings/worker/$userId/';

  // Orders
  static const String orders = 'orders/';
  static String orderAccept(int id) => 'orders/$id/accept/';
  static String orderReject(int id) => 'orders/$id/reject/';
  static String orderCancel(int id) => 'orders/$id/cancel/';
  static String orderComplete(int id) => 'orders/$id/complete/';

  // Notifications
  static const String notifications = 'notifications/';
  static const String notificationsUnreadCount = 'notifications/unread-count/';
  static const String notificationsReadAll = 'notifications/read-all/';
  static const String deviceTokens = 'notifications/devices/';

  // Ratings & favorites
  static const String ratings = 'ratings/';
  static const String favorites = 'favorites/';
  static String favoriteByWorker(int workerId) =>
      'favorites/worker/$workerId/';

  // Health
  static const String health = 'health/';
}
