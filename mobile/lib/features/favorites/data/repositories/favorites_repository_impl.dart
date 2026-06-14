import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/favorites/data/models/favorite_model.dart';
import 'package:mongez/features/favorites/domain/favorites_repository.dart';
import 'package:mongez/services/api_service.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final ApiService apiService;

  FavoritesRepositoryImpl(this.apiService);

  @override
  Future<Either<Failure, List<FavoriteModel>>> getFavorites() async {
    try {
      final data = await apiService.get(endPoint: Endpoints.favorites);
      final list = data as List<dynamic>? ?? [];
      final favorites = list.map((e) => FavoriteModel.fromJson(e)).toList();
      return right(favorites);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FavoriteModel>> addFavorite(int workerId) async {
    try {
      final data = await apiService.post(
        endPoint: Endpoints.favorites,
        body: {'worker_id': workerId},
      );
      return right(FavoriteModel.fromJson(data));
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFavorite(int id) async {
    try {
      await apiService.delete(endPoint: Endpoints.favoriteById(id));
      return right(null);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }
}
