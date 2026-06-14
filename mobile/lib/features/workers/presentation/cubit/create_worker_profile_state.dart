part of 'create_worker_profile_cubit.dart';

@immutable
sealed class CreateWorkerProfileState {
  const CreateWorkerProfileState();
}

final class CreateWorkerProfileInitial extends CreateWorkerProfileState {
  const CreateWorkerProfileInitial();
}

final class CreateWorkerProfileLoading extends CreateWorkerProfileState {
  const CreateWorkerProfileLoading();
}

final class CreateWorkerProfileSuccess extends CreateWorkerProfileState {
  final WorkerModel profile;
  const CreateWorkerProfileSuccess({required this.profile});
}

final class CreateWorkerProfileFailure extends CreateWorkerProfileState {
  final String errorMessage;
  const CreateWorkerProfileFailure({required this.errorMessage});
}
