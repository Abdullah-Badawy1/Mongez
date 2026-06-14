import 'package:dartz/dartz.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/workers/data/models/worker_model.dart';

abstract class WorkerRepository {
  Future<Either<Failure, List<WorkerModel>>> getWorkers({
    int? categoryId,
    String? search,
    int page = 1,
    int pageSize = 20,
  });
  Future<Either<Failure, WorkerModel>> getWorkerById(int id);
  Future<Either<Failure, WorkerModel>> createWorkerProfile({
    int? categoryId,
    required int experienceYears,
    required bool isAvailable,
    String description = '',
  });
}
