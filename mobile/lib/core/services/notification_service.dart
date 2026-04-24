import 'package:dio/dio.dart';
import 'package:mongez/core/api/api_client.dart';
import 'package:mongez/core/api/api_constants.dart';
import 'package:mongez/core/models/notification_model.dart';

class NotificationService {
  final Dio _dio = ApiClient().dio;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _dio.get(ApiConstants.notifications);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAllRead() async =>
      _dio.post(ApiConstants.notificationsReadAll);

  Future<void> markOneRead(int id) async =>
      _dio.post('${ApiConstants.notifications}$id/read/');
}
