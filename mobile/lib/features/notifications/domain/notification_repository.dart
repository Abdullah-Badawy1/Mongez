import 'package:dartz/dartz.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/notifications/data/models/notification_model.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationModel>>> getNotifications();
  Future<Either<Failure, void>> markAsRead(int id);
  Future<Either<Failure, void>> markAllAsRead();
}
