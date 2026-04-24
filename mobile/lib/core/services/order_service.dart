import 'package:dio/dio.dart';
import 'package:mongez/core/api/api_client.dart';
import 'package:mongez/core/api/api_constants.dart';
import 'package:mongez/core/models/order_model.dart';

class OrderService {
  final Dio _dio = ApiClient().dio;

  Future<List<OrderModel>> getOrders() async {
    final response = await _dio.get(ApiConstants.orders);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createOrder({
    required int serviceCategoryId,
    int? workerId,
  }) async {
    final body = <String, dynamic>{'service_category': serviceCategoryId};
    if (workerId != null) body['worker_id'] = workerId;
    final response = await _dio.post(ApiConstants.orders, data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<OrderModel> getOrderById(int id) async {
    final response = await _dio.get('${ApiConstants.orders}$id/');
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> acceptOrder(int id) async =>
      _dio.post('${ApiConstants.orders}$id/accept/');

  Future<void> rejectOrder(int id) async =>
      _dio.post('${ApiConstants.orders}$id/reject/');

  Future<void> cancelOrder(int id) async =>
      _dio.post('${ApiConstants.orders}$id/cancel/');

  Future<void> completeOrder(int id) async =>
      _dio.post('${ApiConstants.orders}$id/complete/');
}
