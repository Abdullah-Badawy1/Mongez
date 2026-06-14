import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:mongez/features/notifications/data/models/notification_model.dart';
import 'package:mongez/features/notifications/domain/notification_repository.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository notificationRepository;
  List<NotificationModel>? _cached;
  Timer? _pollTimer;

  NotificationCubit({required this.notificationRepository})
      : super(NotificationInitial());

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  void reset() => emit(NotificationInitial());

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetch());
    _fetch();
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _fetch() async {
    final result = await notificationRepository.getNotifications();
    result.fold(
      (failure) {
        if (_cached != null) {
          emit(NotificationSuccess(_cached!));
        }
      },
      (notifications) {
        _cached = notifications;
        emit(NotificationSuccess(notifications));
      },
    );
  }

  Future<void> refresh() => _fetch();

  int get unreadCount {
    if (_cached == null) return 0;
    return _cached!.where((n) => !n.isRead).length;
  }

  Future<void> markAsRead(int id) async {
    final result = await notificationRepository.markAsRead(id);
    result.fold(
      (_) {},
      (_) {
        if (_cached != null) {
          _cached = _cached!.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
          emit(NotificationSuccess(_cached!));
        }
      },
    );
  }

  Future<void> markAllAsRead() async {
    final result = await notificationRepository.markAllAsRead();
    result.fold(
      (_) {},
      (_) {
        if (_cached != null) {
          _cached = _cached!.map((n) => n.copyWith(isRead: true)).toList();
          emit(NotificationSuccess(_cached!));
        }
      },
    );
  }
}
