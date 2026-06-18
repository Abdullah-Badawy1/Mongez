import 'package:dartz/dartz.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/orders/data/models/order_model.dart';
import 'package:mongez/models/picked_attachment.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<OrderModel>>> getOrders();
  Future<Either<Failure, OrderModel>> getOrderById(int id);
  Future<Either<Failure, OrderModel>> createOrder({
    required int serviceCategory,
    required int workerId,
    required String description,
    String? address,
    String? phone,
    String? urgency,
    double? latitude,
    double? longitude,
    List<PickedAttachment> photos,
    String? audioPath,
    int? audioDurationSeconds,
  });
  Future<Either<Failure, OrderModel>> acceptOrder(int id);
  Future<Either<Failure, OrderModel>> rejectOrder(int id);
  Future<Either<Failure, void>> cancelOrder(int id);
  Future<Either<Failure, OrderModel>> markAsFinished(int id);
  Future<Either<Failure, OrderModel>> confirmCompletion(int id);
}
