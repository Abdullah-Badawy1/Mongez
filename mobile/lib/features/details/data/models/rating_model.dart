class RatingModel {
  final int id;
  final String? clientName;
  final int stars;
  final String review;
  final String? createdAt;

  RatingModel({
    required this.id,
    this.clientName,
    required this.stars,
    required this.review,
    this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] as int,
      clientName: json['client_name'] as String?,
      stars: json['stars'] as int,
      review: json['review'] as String? ?? '',
      createdAt: json['created_at'] as String?,
    );
  }
}
