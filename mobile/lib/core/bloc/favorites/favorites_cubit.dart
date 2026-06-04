import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/api/api_error.dart';
import 'package:mongez/core/services/favorite_service.dart';
import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final FavoriteService _service = FavoriteService();

  FavoritesCubit() : super(FavoritesInitial());

  Future<void> loadFavorites() async {
    emit(FavoritesLoading());
    try {
      final list = await _service.getFavorites();
      emit(FavoritesLoaded(list));
    } catch (e) {
      emit(FavoritesError(_msg(e)));
    }
  }

  Future<void> addFavorite(int workerId) async {
    try {
      await _service.addFavorite(workerId);
      await loadFavorites();
    } catch (e) {
      emit(FavoritesError(_msg(e)));
    }
  }

  Future<void> removeFavorite(int favoriteId) async {
    try {
      await _service.removeFavorite(favoriteId);
      await loadFavorites();
    } catch (e) {
      emit(FavoritesError(_msg(e)));
    }
  }

  String _msg(Object e) =>
      e is ApiError ? e.message : ApiError.from(e).message;
}
