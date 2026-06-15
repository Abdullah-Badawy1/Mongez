import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mongez/features/workers/data/models/worker_stats.dart';
import 'package:mongez/features/workers/domain/worker_repository.dart';

part 'worker_stats_state.dart';

/// Loads (and refreshes) the logged-in worker's performance summary,
/// and toggles availability without forcing the user back to the
/// edit-profile screen.
class WorkerStatsCubit extends Cubit<WorkerStatsState> {
  WorkerStatsCubit({required this.workerRepository})
      : super(const WorkerStatsInitial());

  final WorkerRepository workerRepository;

  WorkerStats? _cached;

  Future<void> load() async {
    // Don't flash Loading if we already have data — silent refresh.
    if (_cached == null) emit(const WorkerStatsLoading());
    final result = await workerRepository.getMyStats();
    result.fold(
      (failure) {
        // Workers without a profile see a friendly "no profile yet"
        // state, not a generic error.
        if (failure.errorMessage.toLowerCase().contains('worker profile')) {
          emit(const WorkerStatsNoProfile());
          return;
        }
        if (_cached == null) {
          emit(WorkerStatsFailure(failure.errorMessage));
        }
      },
      (stats) {
        _cached = stats;
        emit(WorkerStatsSuccess(stats));
      },
    );
  }

  void reset() {
    _cached = null;
    emit(const WorkerStatsInitial());
  }

  /// Optimistically flip availability so the toggle feels instant;
  /// fall back to the previous value if the PATCH errors.
  Future<void> toggleAvailability(bool next) async {
    final current = _cached;
    if (current == null) return;
    final optimistic = _withAvailability(current, next);
    _cached = optimistic;
    emit(WorkerStatsSuccess(optimistic));

    final result = await workerRepository.setAvailability(next);
    result.fold(
      (failure) {
        // Revert.
        _cached = current;
        emit(WorkerStatsSuccess(current));
      },
      (confirmed) {
        if (confirmed != next) {
          final corrected = _withAvailability(current, confirmed);
          _cached = corrected;
          emit(WorkerStatsSuccess(corrected));
        }
      },
    );
  }

  WorkerStats _withAvailability(WorkerStats s, bool isAvailable) =>
      WorkerStats(
        profileId: s.profileId,
        profession: s.profession,
        professionAr: s.professionAr,
        isAvailable: isAvailable,
        isVerified: s.isVerified,
        averageRating: s.averageRating,
        orders: s.orders,
        completedJobs: s.completedJobs,
        acceptedJobs: s.acceptedJobs,
        pendingRequests: s.pendingRequests,
        thisMonthOrders: s.thisMonthOrders,
        thisMonthCompleted: s.thisMonthCompleted,
        recentReviews: s.recentReviews,
      );
}
