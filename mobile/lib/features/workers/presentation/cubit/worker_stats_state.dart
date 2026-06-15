part of 'worker_stats_cubit.dart';

abstract class WorkerStatsState extends Equatable {
  const WorkerStatsState();
  @override
  List<Object?> get props => const [];
}

class WorkerStatsInitial extends WorkerStatsState {
  const WorkerStatsInitial();
}

class WorkerStatsLoading extends WorkerStatsState {
  const WorkerStatsLoading();
}

class WorkerStatsSuccess extends WorkerStatsState {
  final WorkerStats stats;
  const WorkerStatsSuccess(this.stats);
  @override
  List<Object?> get props => [
        stats.profileId,
        stats.isAvailable,
        stats.completedJobs,
        stats.pendingRequests,
        stats.thisMonthCompleted,
        stats.averageRating,
      ];
}

/// Worker is logged in but hasn't completed AddService — the screen
/// shows a Complete-your-profile CTA instead of the dashboard cards.
class WorkerStatsNoProfile extends WorkerStatsState {
  const WorkerStatsNoProfile();
}

class WorkerStatsFailure extends WorkerStatsState {
  final String errorMessage;
  const WorkerStatsFailure(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}
