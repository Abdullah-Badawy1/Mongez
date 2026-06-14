import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:mongez/features/workers/data/models/worker_model.dart';
import 'package:mongez/features/workers/domain/worker_repository.dart';

part 'create_worker_profile_state.dart';

class CreateWorkerProfileCubit extends Cubit<CreateWorkerProfileState> {
  CreateWorkerProfileCubit({required this.workerRepository})
      : super(CreateWorkerProfileInitial());

  final WorkerRepository workerRepository;

  void reset() {
    emit(CreateWorkerProfileInitial());
  }

  Future<void> createProfile({
    int? categoryId,
    required int experienceYears,
    required bool isAvailable,
    String description = '',
  }) async {
    emit(CreateWorkerProfileLoading());
    final result = await workerRepository.createWorkerProfile(
      categoryId: categoryId,
      experienceYears: experienceYears,
      isAvailable: isAvailable,
      description: description,
    );
    result.fold(
      (failure) => emit(
        CreateWorkerProfileFailure(errorMessage: failure.errorMessage),
      ),
      (profile) => emit(CreateWorkerProfileSuccess(profile: profile)),
    );
  }
}
