import 'package:dartz/dartz.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/home/models/categories.dart';

abstract class HomeRepo {
  Future<Either<Failure, List<CategoriesModel>>> getAllCategories({
    bool force = false,
  });
}

