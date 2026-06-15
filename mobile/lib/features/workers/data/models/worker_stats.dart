/// Performance summary for the logged-in worker — what
/// `/api/workers/me/stats/` returns.
///
/// Doesn't include money figures because Mongez's design has
/// workers settle job cash with the client in person; the platform
/// only ever sees the commission. Counts and ratings are what
/// drive the worker dashboard card.
class WorkerStats {
  final int profileId;
  final String profession;
  final String professionAr;
  final bool isAvailable;
  final bool isVerified;
  final double averageRating;

  // Lifetime counts.
  final int orders;
  final int completedJobs;
  final int acceptedJobs;
  final int pendingRequests;

  // This calendar month.
  final int thisMonthOrders;
  final int thisMonthCompleted;

  final List<WorkerStatsReview> recentReviews;

  const WorkerStats({
    required this.profileId,
    required this.profession,
    required this.professionAr,
    required this.isAvailable,
    required this.isVerified,
    required this.averageRating,
    required this.orders,
    required this.completedJobs,
    required this.acceptedJobs,
    required this.pendingRequests,
    required this.thisMonthOrders,
    required this.thisMonthCompleted,
    required this.recentReviews,
  });

  factory WorkerStats.fromJson(Map<String, dynamic> json) {
    final p = (json['profile'] as Map?) ?? const {};
    final lifetime = (json['lifetime'] as Map?) ?? const {};
    final month = (json['this_month'] as Map?) ?? const {};
    final reviewsJson = (json['recent_ratings'] as List?) ?? const [];

    return WorkerStats(
      profileId: (p['id'] as num?)?.toInt() ?? 0,
      profession: p['profession'] as String? ?? '',
      professionAr: p['profession_ar'] as String? ?? '',
      isAvailable: p['is_available'] as bool? ?? false,
      isVerified: p['is_verified'] as bool? ?? false,
      averageRating: (p['average_rating'] as num?)?.toDouble() ?? 0.0,
      orders: (lifetime['orders'] as num?)?.toInt() ?? 0,
      completedJobs: (lifetime['completed_jobs'] as num?)?.toInt() ?? 0,
      acceptedJobs: (lifetime['accepted_jobs'] as num?)?.toInt() ?? 0,
      pendingRequests: (lifetime['pending_requests'] as num?)?.toInt() ?? 0,
      thisMonthOrders: (month['orders'] as num?)?.toInt() ?? 0,
      thisMonthCompleted: (month['completed_jobs'] as num?)?.toInt() ?? 0,
      recentReviews: reviewsJson
          .whereType<Map<String, dynamic>>()
          .map(WorkerStatsReview.fromJson)
          .toList(growable: false),
    );
  }
}

class WorkerStatsReview {
  final int stars;
  final String review;
  final String clientUsername;
  final DateTime createdAt;

  const WorkerStatsReview({
    required this.stars,
    required this.review,
    required this.clientUsername,
    required this.createdAt,
  });

  factory WorkerStatsReview.fromJson(Map<String, dynamic> json) =>
      WorkerStatsReview(
        stars: (json['stars'] as num?)?.toInt() ?? 0,
        review: json['review'] as String? ?? '',
        clientUsername: json['client_username'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
