class Endpoints {
  Endpoints._();

  // ── Auth ──
  static const String login = 'auth/login/';
  static const String register = 'auth/register/';
  static const String refreshToken = 'auth/token/refresh/';

  // ── Profile ──
  static const String userMe = 'users/me/';

  // ── Categories ──
  static const String categories = 'categories/';

  // ── Reference data ──
  // Hydrates the governorate dropdown on the register screen + any
  // future address-picker. Public endpoint, no auth required.
  static const String governorates = 'governorates/';

  // ── Workers ──
  static const String workers = 'workers/';
  static const String workersCreate = 'workers/create/';
  static const String workersMe = 'workers/me/';
  static String workerById(int id) => 'workers/$id/';
  // Backend serves the calling worker's own profile (includes averageRating
  // + completedJobs) at /workers/me/. There is no dedicated "my-ratings"
  // endpoint, so we reuse /workers/me/ here.
  static const String workerMyRatings = 'workers/me/';
  // Backend serves per-worker ratings under the ratings app.
  static String workerRatings(int id) => 'ratings/worker/$id/';
  static String workerStats(int id) => 'workers/$id/stats/';

  // ── Orders ──
  static const String orders = 'orders/';
  static String orderById(int id) => 'orders/$id/';
  static String orderAccept(int id) => 'orders/$id/accept/';
  static String orderReject(int id) => 'orders/$id/reject/';
  static String orderCancel(int id) => 'orders/$id/cancel/';
  // Backend only supports a single-step completion: the assigned worker
  // calls /complete/. Mobile's "mark finished" and "confirm completion"
  // both map to that — customer calls will return 403, handled at the UI.
  static String orderMarkFinished(int id) => 'orders/$id/complete/';
  static String orderConfirmCompletion(int id) => 'orders/$id/complete/';

  // ── Favorites ──
  static const String favorites = 'favorites/';
  static String favoriteById(int id) => 'favorites/$id/';

  // ── Ratings ──
  static const String ratings = 'ratings/';

  // ── Notifications ──
  static const String notifications = 'notifications/';
  static String notificationRead(int id) => 'notifications/$id/read/';
  static const String notificationsReadAll = 'notifications/read-all/';
}
