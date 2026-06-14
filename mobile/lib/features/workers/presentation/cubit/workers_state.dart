part of 'workers_cubit.dart';

abstract class WorkersState {}

class WorkersInitial extends WorkersState {}

class WorkersLoading extends WorkersState {}

class WorkersSuccess extends WorkersState {
  final List<WorkerModel> workers;
  WorkersSuccess(this.workers);
}

class WorkersFailure extends WorkersState {
  final String errorMessage;
  WorkersFailure(this.errorMessage);
}
