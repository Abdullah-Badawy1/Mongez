import 'package:dio/dio.dart';
import 'package:mongez/core/api/api_client.dart';
import 'package:mongez/core/api/api_constants.dart';
import 'package:mongez/core/api/api_error.dart';
import 'package:mongez/core/models/favorite_model.dart';

class FavoriteService {
  final Dio _dio = ApiClient().dio;

  Future<List<FavoriteModel>> getFavorites() async {
    try {
      final response = await _dio.get(ApiConstants.favorites);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<void> addFavorite(int workerId) async {
    try {
      await _dio.post(ApiConstants.favorites, data: {'worker_id': workerId});
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<void> removeFavorite(int favoriteId) async {
    try {
      await _dio.delete('${ApiConstants.favorites}$favoriteId/');
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  /// Convenience: remove by worker id (no need to know the favorite row id).
  Future<void> removeFavoriteByWorker(int workerId) async {
    try {
      await _dio.delete(ApiConstants.favoriteByWorker(workerId));
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }
}
