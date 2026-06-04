import 'package:dio/dio.dart';
import 'package:mongez/core/api/api_client.dart';
import 'package:mongez/core/api/api_constants.dart';
import 'package:mongez/core/api/api_error.dart';
import 'package:mongez/core/models/notification_model.dart';

class NotificationService {
  final Dio _dio = ApiClient().dio;

  Future<List<NotificationModel>> getNotifications({bool unreadOnly = false}) async {
    try {
      final response = await _dio.get(
        ApiConstants.notifications,
        queryParameters: unreadOnly ? {'unread': 1} : null,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final response = await _dio.get(ApiConstants.notificationsUnreadCount);
      return (response.data['unread'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post(ApiConstants.notificationsReadAll);
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<void> markOneRead(int id) async {
    try {
      await _dio.post('${ApiConstants.notifications}$id/read/');
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  /// Register an FCM token. Idempotent — backend upserts on conflict.
  Future<void> registerDeviceToken({
    required String token,
    String platform = 'android',
  }) async {
    try {
      await _dio.post(
        ApiConstants.deviceTokens,
        data: {'token': token, 'platform': platform},
      );
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<void> unregisterDeviceToken(String token) async {
    try {
      await _dio.delete(ApiConstants.deviceTokens, data: {'token': token});
    } on DioException catch (_) {
      // Best effort.
    }
  }
}
