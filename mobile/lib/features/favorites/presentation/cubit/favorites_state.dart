part of 'favorites_cubit.dart';

abstract class FavoritesState {}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesSuccess extends FavoritesState {
  final List<FavoriteModel> favorites;
  final Set<int> favoriteWorkerIds;
  final Set<int> togglingIds;

  FavoritesSuccess(
    this.favorites, {
    Set<int>? favoriteWorkerIds,
    Set<int>? togglingIds,
  })  : favoriteWorkerIds = favoriteWorkerIds ?? {},
        togglingIds = togglingIds ?? {};
}

class FavoritesEmpty extends FavoritesState {}

class FavoritesFailure extends FavoritesState {
  final String errorMessage;
  FavoritesFailure(this.errorMessage);
}
