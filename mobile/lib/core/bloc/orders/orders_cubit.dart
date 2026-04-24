import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/services/order_service.dart';
import 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final OrderService _service = OrderService();

  OrdersCubit() : super(OrdersInitial());

  Future<void> loadOrders() async {
    emit(OrdersLoading());
    try {
      final orders = await _service.getOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> createOrder({required int categoryId, int? workerId}) async {
    emit(OrdersLoading());
    try {
      await _service.createOrder(
        serviceCategoryId: categoryId,
        workerId: workerId,
      );
      emit(OrderActionSuccess('Order placed successfully'));
      await loadOrders();
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> cancelOrder(int id) async {
    try {
      await _service.cancelOrder(id);
      emit(OrderActionSuccess('Order cancelled'));
      await loadOrders();
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> acceptOrder(int id) async {
    try {
      await _service.acceptOrder(id);
      emit(OrderActionSuccess('Order accepted'));
      await loadOrders();
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> rejectOrder(int id) async {
    try {
      await _service.rejectOrder(id);
      emit(OrderActionSuccess('Order rejected'));
      await loadOrders();
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> completeOrder(int id) async {
    try {
      await _service.completeOrder(id);
      emit(OrderActionSuccess('Order completed'));
      await loadOrders();
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }
}
