import 'package:bloc/bloc.dart';
import 'package:mongez/features/orders/data/models/order_model.dart';
import 'package:mongez/features/orders/domain/order_repository.dart';

part 'customer_orders_state.dart';

class CustomerOrdersCubit extends Cubit<CustomerOrdersState> {
  final OrderRepository orderRepository;
  List<OrderModel>? _cachedOrders;

  CustomerOrdersCubit({required this.orderRepository})
      : super(CustomerOrdersInitial());

  void reset() => emit(CustomerOrdersInitial());

  Future<void> getOrders() async {
    emit(CustomerOrdersLoading());
    await _loadOrders();
  }

  Future<void> _loadOrders() async {
    final result = await orderRepository.getOrders();
    result.fold(
      (failure) => emit(CustomerOrdersFailure(failure.errorMessage)),
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
