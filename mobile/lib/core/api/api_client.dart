import 'package:dio/dio.dart';
import 'package:mongez/core/api/api_constants.dart';
import 'package:mongez/core/helpers.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio = _buildDio();

  Dio get dio => _dio;

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
          final token = AppPrefs.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final refreshed = await _tryRefreshToken(dio);
            if (refreshed) {
              final opts = e.requestOptions;
              opts.headers['Authorization'] =
                  'Bearer ${AppPrefs.accessToken}';
              try {
                final response = await dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {}
            }
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
}
