class ApiConstants {
  // Change to http://10.0.2.2:8000/api/ when using Android emulator
  static const String baseUrl = 'http://localhost:8000/api/';

  static const String register = 'auth/register/';
  static const String login = 'auth/login/';
  static const String tokenRefresh = 'auth/token/refresh/';

  static const String me = 'users/me/';

  static const String categories = 'categories/';

  static const String workers = 'workers/';
  static const String workersMe = 'workers/me/';
  static const String workersCreate = 'workers/create/';

  static const String orders = 'orders/';

  static const String notifications = 'notifications/';
  static const String notificationsReadAll = 'notifications/read-all/';

  static const String ratings = 'ratings/';

  static const String favorites = 'favorites/';
}
