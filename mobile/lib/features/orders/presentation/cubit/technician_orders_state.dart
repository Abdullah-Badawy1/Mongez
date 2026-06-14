part of 'technician_orders_cubit.dart';

abstract class TechnicianOrdersState {}

class TechnicianOrdersInitial extends TechnicianOrdersState {}

class TechnicianOrdersLoading extends TechnicianOrdersState {}

class TechnicianOrdersSuccess extends TechnicianOrdersState {
  final List<OrderModel> orders;
  TechnicianOrdersSuccess(this.orders);
}

class TechnicianOrdersEmpty extends TechnicianOrdersState {}

class TechnicianOrdersFailure extends TechnicianOrdersState {
  final String errorMessage;
  TechnicianOrdersFailure(this.errorMessage);
}
