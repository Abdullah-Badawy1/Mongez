import 'package:dio/dio.dart';
import 'package:mongez/core/api/api_client.dart';
import 'package:mongez/core/api/api_constants.dart';
import 'package:mongez/core/models/favorite_model.dart';

class FavoriteService {
  final Dio _dio = ApiClient().dio;

  Future<List<FavoriteModel>> getFavorites() async {
    final response = await _dio.get(ApiConstants.favorites);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addFavorite(int workerId) async =>
      _dio.post(ApiConstants.favorites, data: {'worker_id': workerId});

  Future<void> removeFavorite(int favoriteId) async =>
      _dio.delete('${ApiConstants.favorites}$favoriteId/');
}
