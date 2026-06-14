import 'package:dartz/dartz.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/favorites/data/models/favorite_model.dart';

abstract class FavoritesRepository {
  Future<Either<Failure, List<FavoriteModel>>> getFavorites();
  Future<Either<Failure, FavoriteModel>> addFavorite(int workerId);
  Future<Either<Failure, void>> removeFavorite(int id);
}
