import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/home/models/categories.dart';
import 'package:mongez/features/home/repos/home_repo.dart';
import 'package:mongez/services/api_service.dart';

class HomeRepoImplementation implements HomeRepo {
  final ApiService apiService;
  HomeRepoImplementation(this.apiService);

  // Process-lifetime cache for /api/categories/. The list changes only
  // when an admin edits a category in the dashboard, and the dashboard
  // already calls `referenceAPI.listGovernorates()`-style invalidations
  // for itself. On the mobile we accept a small staleness window in
  // exchange for an instant "add service" / "place order" screen.
  List<CategoriesModel>? _categoriesCache;
  DateTime? _categoriesCachedAt;
  static const _categoriesTtl = Duration(minutes: 5);

  /// `force: true` bypasses the cache — used by pull-to-refresh /
  /// after the dashboard signals an edit.
  @override
  Future<Either<Failure, List<CategoriesModel>>> getAllCategories({
    bool force = false,
  }) async {
    if (!force &&
        _categoriesCache != null &&
        _categoriesCachedAt != null &&
        DateTime.now().difference(_categoriesCachedAt!) < _categoriesTtl) {
      return right(_categoriesCache!);
    }

    try {
      final data = await apiService.get(endPoint: "categories/");
      final categories = (data as List)
          .map((e) => CategoriesModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      _categoriesCache = categories;
      _categoriesCachedAt = DateTime.now();
      return right(categories);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }
}

