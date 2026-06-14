import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/home/models/categories.dart';
import 'package:mongez/features/home/repos/home_repo.dart';
import 'package:mongez/services/api_service.dart';

class HomeRepoImplementation implements HomeRepo {
  ApiService apiService;

  HomeRepoImplementation(this.apiService);

  @override
  Future<Either<Failure, List<CategoriesModel>>> getAllCategories() async {
    try {
      var data = await apiService.get(endPoint: "categories/");

      List<CategoriesModel> categories = (data as List)
          .map((e) => CategoriesModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return right(categories);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      } else {
        return left(ServerFailure(errorMessage: e.toString()));
      }
    }
  }
}

