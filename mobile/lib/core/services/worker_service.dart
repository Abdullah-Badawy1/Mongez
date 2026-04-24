import 'package:dio/dio.dart';
import 'package:mongez/core/api/api_client.dart';
import 'package:mongez/core/api/api_constants.dart';
import 'package:mongez/core/models/category_model.dart';
import 'package:mongez/core/models/worker_model.dart';

class WorkerService {
  final Dio _dio = ApiClient().dio;

  Future<List<CategoryModel>> getCategories() async {
    final response = await _dio.get(ApiConstants.categories);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WorkerModel>> getWorkers({
    int? categoryId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (categoryId != null) params['category'] = categoryId;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _dio.get(
      ApiConstants.workers,
      queryParameters: params,
    );

    final data = response.data;
    List<dynamic> results;
    if (data is List) {
      results = data;
    } else if (data is Map && data['results'] != null) {
      results = data['results'] as List<dynamic>;
    } else {
      results = [];
    }

    return results
        .map((e) => WorkerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WorkerModel> getWorkerById(int id) async {
    final response = await _dio.get('${ApiConstants.workers}$id/');
    return WorkerModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WorkerModel> getMyWorkerProfile() async {
    final response = await _dio.get(ApiConstants.workersMe);
    return WorkerModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WorkerModel> createWorkerProfile({
    required String profession,
    required int experienceYears,
    bool isAvailable = true,
  }) async {
    final response = await _dio.post(
      ApiConstants.workersCreate,
      data: {
        'profession': profession,
        'experience_years': experienceYears,
        'is_available': isAvailable,
      },
    );
    return WorkerModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WorkerModel> updateMyProfile({
    String? profession,
    int? experienceYears,
    bool? isAvailable,
  }) async {
    final body = <String, dynamic>{};
    if (profession != null) body['profession'] = profession;
    if (experienceYears != null) body['experience_years'] = experienceYears;
    if (isAvailable != null) body['is_available'] = isAvailable;
    final response = await _dio.patch(ApiConstants.workersMe, data: body);
    return WorkerModel.fromJson(response.data as Map<String, dynamic>);
  }
}
