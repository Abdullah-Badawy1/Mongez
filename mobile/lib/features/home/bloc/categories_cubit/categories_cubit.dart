import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:mongez/features/home/models/categories.dart';
import 'package:mongez/features/home/repos/home_repo.dart';

part 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit({required this.homeRepo}) : super(CategoriesInitial());
  final HomeRepo homeRepo;

  late List<CategoriesModel> categories;

  void reset() {
    emit(CategoriesInitial());
  }

  Future<void> fetchCategories() async {
    emit(CategoriesLoading());

    final result = await homeRepo.getAllCategories();

    result.fold(
      (failure) => emit(CategoriesFailure(errorMessage: failure.errorMessage)),
      (categories) {
        this.categories = categories;
        emit(CategoriesSuccess(categories: categories));
      },
    );
  }
}

