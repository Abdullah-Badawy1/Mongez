import 'package:dio/dio.dart';
import 'package:mongez/core/api/api_constants.dart';
import 'package:mongez/core/cache/json_cache.dart';
import 'package:mongez/core/helpers.dart';

/// Singleton Dio client with two interceptor responsibilities:
///   1. Inject `Authorization: Bearer <access>` on every request.
///   2. On 401, try a refresh; if that fails, clear all local auth + cache so
///      the app can route back to the login flow on next launch instead of
///      surfacing a raw `DioException` to the user.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio = _buildDio();

  Dio get dio => _dio;

  /// Optional callback the app sets at boot. Lets ApiClient tell the rest of
  /// the app "we lost auth, route to login" without dragging a BLoC dep here.
  void Function()? _onUnauthorized;
  void onUnauthorized(void Function() handler) => _onUnauthorized = handler;

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Skip the auth header on the refresh endpoint itself, otherwise
          // an expired access token leaks through and bumps the auth throttle.
          final isRefresh = options.path.endsWith(ApiConstants.tokenRefresh);
          final token = AppPrefs.accessToken;
          if (token != null && !isRefresh) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          final code = e.response?.statusCode;
          final isRefreshCall =
              e.requestOptions.path.endsWith(ApiConstants.tokenRefresh);

          // Only intervene on 401, and never on the refresh call itself
          // (otherwise we'd loop). 429 from the auth throttle should also
          // bypass refresh.
          if (code == 401 && !isRefreshCall) {
            final refreshed = await _tryRefreshToken(dio);
            if (refreshed) {
              final opts = e.requestOptions;
              opts.headers['Authorization'] =
                  'Bearer ${AppPrefs.accessToken}';
              try {
                final response = await dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {
                // Fall through to the logout path below.
              }
            }
            // Refresh failed (or got throttled) → tokens are useless.
            await _wipeAuth();
            _onUnauthorized?.call();
          }
          return handler.next(e);
        },
      ),
    );

    return dio;
  }

  Future<bool> _tryRefreshToken(Dio dio) async {
    final refresh = AppPrefs.refreshToken;
    if (refresh == null) return false;
    try {
      final response = await dio.post(
        ApiConstants.tokenRefresh,
        data: {'refresh': refresh},
        options: Options(headers: {}),
      );
      final newAccess = response.data['access'] as String?;
      if (newAccess != null) {
        await AppPrefs.setAccessToken(newAccess);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _wipeAuth() async {
    await AppPrefs.clearTokens();
    await JsonCache.clearAll();
  }
}
