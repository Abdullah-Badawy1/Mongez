class PaginationResult {
  final int? currentPage;
  final int? limit;
  final int? numberOfPages;

  const PaginationResult({this.currentPage, this.limit, this.numberOfPages});

  factory PaginationResult.fromJson(Map<String, dynamic> json) {
    return PaginationResult(
      currentPage: json['currentPage'] as int?,
      limit: json['limit'] as int?,
      numberOfPages: json['numberOfPages'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentPage': currentPage,
    'limit': limit,
    'numberOfPages': numberOfPages,
  };
}
