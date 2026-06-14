part of 'notification_cubit.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationSuccess extends NotificationState {
  final List<NotificationModel> notifications;
  NotificationSuccess(this.notifications);
}

class NotificationFailure extends NotificationState {
  final String errorMessage;
  NotificationFailure(this.errorMessage);
}
