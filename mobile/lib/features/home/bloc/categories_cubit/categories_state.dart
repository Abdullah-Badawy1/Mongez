part of 'categories_cubit.dart';

@immutable
sealed class CategoriesState {}

final class CategoriesInitial extends CategoriesState {}

final class CategoriesLoading extends CategoriesState {}

final class CategoriesSuccess extends CategoriesState {
  final List<CategoriesModel> categories;

  CategoriesSuccess({required this.categories});
}

final class CategoriesFailure extends CategoriesState {
  final String errorMessage;

  CategoriesFailure({required this.errorMessage});
}
