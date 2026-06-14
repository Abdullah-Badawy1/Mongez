import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/workers/data/models/worker_model.dart';
import 'package:mongez/features/workers/domain/worker_repository.dart';
import 'package:mongez/services/api_service.dart';

class WorkerRepositoryImpl implements WorkerRepository {
  final ApiService apiService;

  WorkerRepositoryImpl(this.apiService);

  @override
  Future<Either<Failure, List<WorkerModel>>> getWorkers({
    int? categoryId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (categoryId != null) queryParams['category'] = categoryId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final data = await apiService.get(
        endPoint: Endpoints.workers,
        queryParameters: queryParams,
      );

      final list = data['results'] as List<dynamic>? ?? [];
      final workers = list.map((e) => WorkerModel.fromJson(e)).toList();
      return right(workers);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkerModel>> getWorkerById(int id) async {
    try {
      final data = await apiService.get(endPoint: Endpoints.workerById(id));
      return right(WorkerModel.fromJson(data));
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkerModel>> createWorkerProfile({
    int? categoryId,
    required int experienceYears,
    required bool isAvailable,
    String description = '',
  }) async {
    try {
      final body = <String, dynamic>{
        'is_available': isAvailable,
        'experience_years': experienceYears,
        'description': description,
      };
      if (categoryId != null) {
        body['category_id'] = categoryId;
      }
      final data = await apiService.post(
        endPoint: Endpoints.workersCreate,
        body: body,
      );
      return right(WorkerModel.fromJson(data));
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }
}
