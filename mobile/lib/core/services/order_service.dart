import 'package:dio/dio.dart';
import 'package:mongez/core/api/api_client.dart';
import 'package:mongez/core/api/api_constants.dart';
import 'package:mongez/core/api/api_error.dart';
import 'package:mongez/core/cache/json_cache.dart';
import 'package:mongez/core/models/order_model.dart';

class OrderService {
  static const _ordersKey = 'orders_mine';

  final Dio _dio = ApiClient().dio;

  Future<List<OrderModel>> getOrders({String? statusFilter}) async {
    final params = <String, dynamic>{};
    if (statusFilter != null) params['status'] = statusFilter;

    try {
      final response = await _dio.get(
        ApiConstants.orders,
        queryParameters: params.isEmpty ? null : params,
      );
      final list = response.data as List<dynamic>;
      if (statusFilter == null) {
        await JsonCache.write(_ordersKey, list);
      }
      return list
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (statusFilter == null) {
        final cached = await JsonCache.read(_ordersKey);
        if (cached is List) {
          return cached
              .map((e) => OrderModel.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList();
        }
      }
      throw ApiError.from(e);
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required int serviceCategoryId,
    int? workerId,
  }) async {
    final body = <String, dynamic>{'service_category': serviceCategoryId};
    if (workerId != null) body['worker_id'] = workerId;
    try {
      final response = await _dio.post(ApiConstants.orders, data: body);
      // Invalidate stale list cache so the next read fetches fresh.
      await JsonCache.remove(_ordersKey);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<OrderModel> getOrderById(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.orders}$id/');
      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<OrderModel> acceptOrder(int id) =>
      _stateTransition(ApiConstants.orderAccept(id));

  Future<OrderModel> rejectOrder(int id) =>
      _stateTransition(ApiConstants.orderReject(id));

  Future<OrderModel> cancelOrder(int id) =>
      _stateTransition(ApiConstants.orderCancel(id));

  Future<OrderModel> completeOrder(int id) =>
      _stateTransition(ApiConstants.orderComplete(id));

  Future<OrderModel> _stateTransition(String path) async {
    try {
      final response = await _dio.post(path);
      await JsonCache.remove(_ordersKey);
      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }
}
