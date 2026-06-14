part of 'customer_orders_cubit.dart';

abstract class CustomerOrdersState {}

class CustomerOrdersInitial extends CustomerOrdersState {}

class CustomerOrdersLoading extends CustomerOrdersState {}

class CustomerOrdersSuccess extends CustomerOrdersState {
  final List<OrderModel> orders;
  CustomerOrdersSuccess(this.orders);
}

class CustomerOrdersEmpty extends CustomerOrdersState {}

class CustomerOrdersFailure extends CustomerOrdersState {
  final String errorMessage;
  CustomerOrdersFailure(this.errorMessage);
}
