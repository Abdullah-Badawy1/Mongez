import 'datum.dart';
import 'pagination_result.dart';

class CategoryModel {
  final int? results;
  final PaginationResult? paginationResult;
  final List<Categories>? data;

  const CategoryModel({this.results, this.paginationResult, this.data});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    results: json['results'] as int?,
    paginationResult: json['paginationResult'] == null
        ? null
        : PaginationResult.fromJson(
            json['paginationResult'] as Map<String, dynamic>,
          ),
    data: (json['data'] as List<dynamic>?)
        ?.map((e) => Categories.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'results': results,
    'paginationResult': paginationResult?.toJson(),
    'data': data?.map((e) => e.toJson()).toList(),
  };
}
