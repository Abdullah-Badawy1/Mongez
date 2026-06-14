import 'package:bloc/bloc.dart';
import 'package:mongez/features/orders/data/models/order_model.dart';
import 'package:mongez/features/orders/domain/order_repository.dart';

part 'job_history_state.dart';

class JobHistoryCubit extends Cubit<JobHistoryState> {
  final OrderRepository orderRepository;

  JobHistoryCubit({required this.orderRepository})
      : super(JobHistoryInitial());

  void reset() => emit(JobHistoryInitial());

  Future<void> getJobHistory() async {
    emit(JobHistoryLoading());
    final result = await orderRepository.getOrders();
    result.fold(
      (failure) => emit(JobHistoryFailure(failure.errorMessage)),
      (orders) {
        final completed = orders
            .where((o) =>
                o.status == OrderStatus.completed ||
                o.status == OrderStatus.cancelled ||
                o.status == OrderStatus.rejected)
            .toList();
        if (completed.isEmpty) {
          emit(JobHistoryEmpty());
        } else {
          emit(JobHistorySuccess(completed));
        }
      },
    );
  }
}
