import 'package:dartz/dartz.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/workers/data/models/worker_model.dart';
import 'package:mongez/features/workers/data/models/worker_stats.dart';

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

  /// `/api/workers/me/stats/` — used by the worker home dashboard card.
  Future<Either<Failure, WorkerStats>> getMyStats();

  /// PATCH `/api/workers/me/` with just `{is_available: ...}`. Returns
  /// the new value on success so the cubit can confirm.
  Future<Either<Failure, bool>> setAvailability(bool isAvailable);
}
