import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/auth/models/governorate.dart';
import 'package:mongez/services/api_service.dart';

/// Loads the 27 Egyptian governorates from the backend (single source
/// of truth, see apps/users/governorates.py). Cached in-memory after
/// the first hit since the list is static — change it on the backend
/// and the next cold start picks the new copy up.
class GovernoratesRepo {
  final ApiService apiService;
  GovernoratesRepo(this.apiService);

  List<Governorate>? _cache;

  Future<Either<Failure, List<Governorate>>> getGovernorates() async {
    if (_cache != null) return right(_cache!);
    try {
      final raw = await apiService.get(endPoint: Endpoints.governorates);
      final list = (raw as List)
          .map((e) => Governorate.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      _cache = list;
      return right(list);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }
}
