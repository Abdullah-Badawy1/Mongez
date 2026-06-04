import 'package:dio/dio.dart';
import 'package:mongez/core/api/api_client.dart';
import 'package:mongez/core/api/api_constants.dart';
import 'package:mongez/core/api/api_error.dart';
import 'package:mongez/core/cache/json_cache.dart';
import 'package:mongez/core/models/category_model.dart';
import 'package:mongez/core/models/worker_model.dart';

class WorkerService {
  static const _categoriesKey = 'categories';
  static const _workersKey = 'workers_default';

  final Dio _dio = ApiClient().dio;

  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await JsonCache.readFresh(
        _categoriesKey,
        const Duration(hours: 6),
      );
      if (cached is List) {
        return cached
            .map((e) => CategoryModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }
    }

    try {
      final response = await _dio.get(ApiConstants.categories);
      final list = response.data as List<dynamic>;
      await JsonCache.write(_categoriesKey, list);
      return list
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // Fall back to stale cache when offline so the UI is not empty.
      final cached = await JsonCache.read(_categoriesKey);
      if (cached is List) {
        return cached
            .map((e) => CategoryModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }
      throw ApiError.from(e);
    }
  }

  Future<List<WorkerModel>> getWorkers({
    int? categoryId,
    String? search,
    double? minRating,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (categoryId != null) params['category'] = categoryId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (minRating != null) params['min_rating'] = minRating;
    if (ordering != null) params['ordering'] = ordering;

    final isDefaultPage =
        categoryId == null && (search == null || search.isEmpty) && page == 1;

    try {
      final response = await _dio.get(
        ApiConstants.workers,
        queryParameters: params,
      );

      final data = response.data;
      final results = data is List
          ? data
          : (data is Map && data['results'] != null
              ? data['results'] as List<dynamic>
              : <dynamic>[]);

      // Only cache the unfiltered first page — that's what the home screen
      // reads when offline. Filtered queries shouldn't pollute the cache.
      if (isDefaultPage) {
        await JsonCache.write(_workersKey, results);
      }

      return results
          .map((e) => WorkerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (isDefaultPage) {
        final cached = await JsonCache.read(_workersKey);
        if (cached is List) {
          return cached
              .map((e) => WorkerModel.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList();
        }
      }
      throw ApiError.from(e);
    }
  }

  Future<WorkerModel> getWorkerById(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.workers}$id/');
      return WorkerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<WorkerStats> getWorkerStats(int id) async {
    try {
      final response = await _dio.get(ApiConstants.workerStats(id));
      return WorkerStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<WorkerModel> getMyWorkerProfile() async {
    try {
      final response = await _dio.get(ApiConstants.workersMe);
      return WorkerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<WorkerModel> createWorkerProfile({
    required String profession,
    required int experienceYears,
    String? bio,
    double? hourlyRate,
    bool isAvailable = true,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.workersCreate,
        data: {
          'profession': profession,
          'experience_years': experienceYears,
          if (bio != null) 'bio': bio,
          if (hourlyRate != null) 'hourly_rate': hourlyRate,
          'is_available': isAvailable,
        },
      );
      return WorkerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<WorkerModel> updateMyProfile({
    String? profession,
    String? bio,
    int? experienceYears,
    double? hourlyRate,
    bool? isAvailable,
  }) async {
    final body = <String, dynamic>{};
    if (profession != null) body['profession'] = profession;
    if (bio != null) body['bio'] = bio;
    if (experienceYears != null) body['experience_years'] = experienceYears;
    if (hourlyRate != null) body['hourly_rate'] = hourlyRate;
    if (isAvailable != null) body['is_available'] = isAvailable;
    try {
      final response = await _dio.patch(ApiConstants.workersMe, data: body);
      return WorkerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }
}
