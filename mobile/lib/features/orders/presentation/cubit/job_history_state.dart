part of 'job_history_cubit.dart';

abstract class JobHistoryState {}

class JobHistoryInitial extends JobHistoryState {}

class JobHistoryLoading extends JobHistoryState {}

class JobHistorySuccess extends JobHistoryState {
  final List<OrderModel> jobs;
  JobHistorySuccess(this.jobs);
}

class JobHistoryEmpty extends JobHistoryState {}

class JobHistoryFailure extends JobHistoryState {
  final String errorMessage;
  JobHistoryFailure(this.errorMessage);
}
