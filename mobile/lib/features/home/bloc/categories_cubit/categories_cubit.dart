import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:mongez/features/home/models/categories.dart';
import 'package:mongez/features/home/repos/home_repo.dart';

part 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit({required this.homeRepo}) : super(CategoriesInitial());
  final HomeRepo homeRepo;

  List<CategoriesModel>? categories;
  bool _inFlight = false;

  void reset() {
    categories = null;
    emit(CategoriesInitial());
  }

  /// `force: true` bypasses the repo cache (used by pull-to-refresh).
  /// Otherwise, the cubit emits `Loading` only when there are no
  /// categories cached locally — repeated callers (register screen
  /// pre-warming, add-service-screen mount, home screen mount) won't
  /// cause a spinner flicker.
  Future<void> fetchCategories({bool force = false}) async {
    if (_inFlight) return;
    _inFlight = true;

    try {
      final hasData = state is CategoriesSuccess && categories != null;
      if (!hasData) {
        emit(CategoriesLoading());
      }

      final result = await homeRepo.getAllCategories(force: force);
      result.fold(
        (failure) {
          // Only surface failure if we have nothing to show — otherwise
          // keep the cached list visible (offline-tolerant).
          if (!hasData) {
            emit(CategoriesFailure(errorMessage: failure.errorMessage));
          }
        },
        (fresh) {
          categories = fresh;
          emit(CategoriesSuccess(categories: fresh));
        },
      );
    } finally {
      _inFlight = false;
    }
  }
}

