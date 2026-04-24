import 'user_model.dart';

class WorkerModel {
  final int id;
  final UserModel user;
  final String profession;
  final int experienceYears;
  final double averageRating;
  final int completedJobs;
  final bool isAvailable;
  final double score;
  final String createdAt;

  const WorkerModel({
    required this.id,
    required this.user,
    required this.profession,
    required this.experienceYears,
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
        experienceYears: json['experience_years'] as int? ?? 0,
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
        completedJobs: json['completed_jobs'] as int? ?? 0,
        isAvailable: json['is_available'] as bool? ?? true,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        createdAt: json['created_at'] as String? ?? '',
      );
}
