import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:mongez/features/orders/data/models/order_model.dart';
import 'package:mongez/features/orders/domain/order_repository.dart';

part 'technician_orders_state.dart';

class TechnicianOrdersCubit extends Cubit<TechnicianOrdersState> {
  final OrderRepository orderRepository;
  List<OrderModel>? _cachedOrders;
  Timer? _pollTimer;

  TechnicianOrdersCubit({required this.orderRepository})
      : super(TechnicianOrdersInitial());

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  void reset() {
    stopPolling();
    emit(TechnicianOrdersInitial());
  }

  Future<void> getOrders() async {
    emit(TechnicianOrdersLoading());
    await _loadOrders();
  }

  /// Background poll — same 30 s cadence as NotificationCubit so a new
  /// PENDING order assigned by a client (or a CANCELLED flip from the
  /// dashboard) lands on the worker's screen without manual refresh.
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadOrders(),
    );
    _loadOrders();
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _loadOrders() async {
    final result = await orderRepository.getOrders();
    result.fold(
      (failure) {
        if (_cachedOrders == null) {
          emit(TechnicianOrdersFailure(failure.errorMessage));
        }
      },
      (orders) {
        _cachedOrders = orders;
        if (orders.isEmpty) {
          emit(TechnicianOrdersEmpty());
        } else {
          emit(TechnicianOrdersSuccess(orders));
        }
      },
    );
  }

  Future<void> acceptOrder(int orderId) async {
    final result = await orderRepository.acceptOrder(orderId);
    if (result.isRight()) {
      await _loadOrders();
    } else {
      _restoreState();
    }
  }

  Future<void> rejectOrder(int orderId) async {
    final result = await orderRepository.rejectOrder(orderId);
    if (result.isRight()) {
      await _loadOrders();
    } else {
      _restoreState();
    }
  }

  Future<void> markAsFinished(int orderId) async {
    final result = await orderRepository.markAsFinished(orderId);
    if (result.isRight()) {
      await _loadOrders();
    } else {
      _restoreState();
    }
  }

  void _restoreState() {
    if (_cachedOrders == null) {
      emit(TechnicianOrdersEmpty());
      return;
    }
    if (_cachedOrders!.isEmpty) {
      emit(TechnicianOrdersEmpty());
    } else {
      emit(TechnicianOrdersSuccess(_cachedOrders!));
    }
  }
}
