import 'user_model.dart';

class WorkerModel {
  final int id;
  final UserModel user;
  final String profession;
  final String bio;
  final int experienceYears;
  final double? hourlyRate;
  final double averageRating;
  final int completedJobs;
  final bool isAvailable;
  final double score;
  final String createdAt;

  const WorkerModel({
    required this.id,
    required this.user,
    required this.profession,
    required this.bio,
    required this.experienceYears,
    required this.hourlyRate,
    required this.averageRating,
    required this.completedJobs,
    required this.isAvailable,
    required this.score,
    required this.createdAt,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) => WorkerModel(
        id: json['id'] as int,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        profession: json['profession'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        experienceYears: json['experience_years'] as int? ?? 0,
        hourlyRate: (json['hourly_rate'] is num)
            ? (json['hourly_rate'] as num).toDouble()
            : (json['hourly_rate'] is String
                ? double.tryParse(json['hourly_rate'] as String)
                : null),
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
        completedJobs: json['completed_jobs'] as int? ?? 0,
        isAvailable: json['is_available'] as bool? ?? true,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        createdAt: json['created_at'] as String? ?? '',
      );
}

class WorkerStats {
  final int workerId;
  final String username;
  final String profession;
  final int experienceYears;
  final bool isAvailable;
  final int totalOrders;
  final int acceptedOrders;
  final int completedOrders;
  final int rejectedOrders;
  final double acceptanceRate;
  final int ratingsCount;
  final double averageRating;
  final Map<String, int> ratingDistribution;
  final double score;

  const WorkerStats({
    required this.workerId,
    required this.username,
    required this.profession,
    required this.experienceYears,
    required this.isAvailable,
    required this.totalOrders,
    required this.acceptedOrders,
    required this.completedOrders,
    required this.rejectedOrders,
    required this.acceptanceRate,
    required this.ratingsCount,
    required this.averageRating,
    required this.ratingDistribution,
    required this.score,
  });

  factory WorkerStats.fromJson(Map<String, dynamic> json) {
    final orders = (json['orders'] as Map?) ?? const {};
    final ratings = (json['ratings'] as Map?) ?? const {};
    final dist = (ratings['distribution'] as Map?) ?? const {};
    return WorkerStats(
      workerId: json['worker_id'] as int,
      username: json['username'] as String? ?? '',
      profession: json['profession'] as String? ?? '',
      experienceYears: json['experience_years'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? false,
      totalOrders: orders['total'] as int? ?? 0,
      acceptedOrders: orders['accepted'] as int? ?? 0,
      completedOrders: orders['completed'] as int? ?? 0,
      rejectedOrders: orders['rejected'] as int? ?? 0,
      acceptanceRate: (orders['acceptance_rate'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: ratings['count'] as int? ?? 0,
      averageRating: (ratings['average'] as num?)?.toDouble() ?? 0.0,
      ratingDistribution: dist.map(
        (k, v) => MapEntry(k as String, (v as num?)?.toInt() ?? 0),
      ),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
