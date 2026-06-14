import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/orders/data/models/order_model.dart';
import 'package:mongez/features/orders/domain/order_repository.dart';
import 'package:mongez/services/api_service.dart';

class OrderRepositoryImpl implements OrderRepository {
  final ApiService apiService;

  OrderRepositoryImpl(this.apiService);

  @override
  Future<Either<Failure, List<OrderModel>>> getOrders() async {
    try {
      final data = await apiService.get(endPoint: Endpoints.orders);
      final list = data as List<dynamic>? ?? [];
      final orders = list.map((e) => OrderModel.fromJson(e)).toList();
      return right(orders);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderModel>> getOrderById(int id) async {
    try {
      final data = await apiService.get(endPoint: Endpoints.orderById(id));
      return right(OrderModel.fromJson(data));
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderModel>> createOrder({
    required int serviceCategory,
    required int workerId,
    required String description,
    String? address,
    String? phone,
    String? urgency,
    double? latitude,
    double? longitude,
    List<String> photoPaths = const [],
    String? audioPath,
    int? audioDurationSeconds,
  }) async {
    try {
      final hasFiles = photoPaths.isNotEmpty || (audioPath?.isNotEmpty ?? false);

      if (!hasFiles) {
        final body = <String, dynamic>{
          'service_category': serviceCategory,
          'worker_id': workerId,
          'description': description,
        };
        if (address != null) body['address_text'] = address;
        if (urgency != null) body['urgency'] = urgency;
        if (latitude != null) body['latitude'] = latitude;
        if (longitude != null) body['longitude'] = longitude;

        final data = await apiService.post(endPoint: Endpoints.orders, body: body);
        return right(OrderModel.fromJson(data));
      }

      final fields = <String, dynamic>{
        'service_category': serviceCategory,
        'worker_id': workerId,
        'description': description,
      };
      if (address != null) fields['address_text'] = address;
      if (urgency != null) fields['urgency'] = urgency;
      if (latitude != null) fields['latitude'] = latitude;
      if (longitude != null) fields['longitude'] = longitude;
      if (audioDurationSeconds != null) {
        fields['duration_seconds'] = audioDurationSeconds;
      }

      final form = FormData.fromMap(fields);
      for (final p in photoPaths) {
        form.files.add(MapEntry('photos', await MultipartFile.fromFile(p)));
      }
      if (audioPath != null && audioPath.isNotEmpty) {
        form.files.add(MapEntry('audio', await MultipartFile.fromFile(audioPath)));
      }
      // Reuse the already-configured Dio (auth interceptor, base URL, etc.)
      // from the registered ApiService, instead of looking up DioClient
      // separately — DioClient is not registered in GetIt.
      final dio = apiService.dioClient.dio;
      final response = await dio.post(Endpoints.orders, data: form);
      return right(OrderModel.fromJson(response.data));
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderModel>> acceptOrder(int id) async {
    try {
      final data = await apiService.post(endPoint: Endpoints.orderAccept(id));
      return right(OrderModel.fromJson(data));
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderModel>> rejectOrder(int id) async {
    try {
      final data = await apiService.post(endPoint: Endpoints.orderReject(id));
      return right(OrderModel.fromJson(data));
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOrder(int id) async {
    try {
      await apiService.post(endPoint: Endpoints.orderCancel(id));
      return right(null);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderModel>> markAsFinished(int id) async {
    try {
      final data = await apiService.post(endPoint: Endpoints.orderMarkFinished(id));
      return right(OrderModel.fromJson(data));
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderModel>> confirmCompletion(int id) async {
    try {
      final data = await apiService.post(endPoint: Endpoints.orderConfirmCompletion(id));
      return right(OrderModel.fromJson(data));
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }
}
