import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:mongez/features/orders/data/models/order_model.dart';
import 'package:mongez/features/orders/domain/order_repository.dart';

part 'customer_orders_state.dart';

class CustomerOrdersCubit extends Cubit<CustomerOrdersState> {
  final OrderRepository orderRepository;
  List<OrderModel>? _cachedOrders;
  Timer? _pollTimer;

  CustomerOrdersCubit({required this.orderRepository})
      : super(CustomerOrdersInitial());

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  void reset() {
    stopPolling();
    emit(CustomerOrdersInitial());
  }

  Future<void> getOrders() async {
    emit(CustomerOrdersLoading());
    await _loadOrders();
  }

  /// Background poll — same 30 s cadence as NotificationCubit. Refreshes
  /// the client's order list silently so an admin or worker status change
  /// shows up without manual pull-to-refresh.
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
        // Poll failure — keep showing the cached list if we have one so
        // the UI doesn't flash an error every time the network blips.
        if (_cachedOrders == null) {
          emit(CustomerOrdersFailure(failure.errorMessage));
        }
      },
      (orders) {
        _cachedOrders = orders;
        if (orders.isEmpty) {
          emit(CustomerOrdersEmpty());
        } else {
          emit(CustomerOrdersSuccess(orders));
        }
      },
    );
  }

  Future<void> confirmCompletion(int orderId) async {
    final result = await orderRepository.confirmCompletion(orderId);
    if (result.isRight()) {
      await _loadOrders();
    } else {
      _restoreState();
    }
  }

  Future<void> cancelOrder(int orderId) async {
    final result = await orderRepository.cancelOrder(orderId);
    if (result.isRight()) {
      await _loadOrders();
    } else {
      _restoreState();
    }
  }

  void _restoreState() {
    if (_cachedOrders == null) {
      emit(CustomerOrdersEmpty());
      return;
    }
    if (_cachedOrders!.isEmpty) {
      emit(CustomerOrdersEmpty());
    } else {
      emit(CustomerOrdersSuccess(_cachedOrders!));
    }
  }
}
