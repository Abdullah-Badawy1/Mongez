import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/models/category_model.dart';
import 'package:mongez/core/models/worker_model.dart';
import 'package:mongez/core/services/worker_service.dart';
import 'workers_state.dart';

class WorkersCubit extends Cubit<WorkersState> {
  final WorkerService _service = WorkerService();

  WorkersCubit() : super(WorkersInitial());

  Future<void> load({int? categoryId, String? search}) async {
    emit(WorkersLoading());
    try {
      final results = await Future.wait([
        _service.getCategories(),
        _service.getWorkers(categoryId: categoryId, search: search),
      ]);
      emit(WorkersLoaded(
        categories: results[0] as List<CategoryModel>,
        workers: results[1] as List<WorkerModel>,
      ));
    } catch (e) {
      emit(WorkersError(e.toString()));
    }
  }

  Future<void> filterByCategory(int categoryId) async {
    final current = state;
    final cats = current is WorkersLoaded ? current.categories : <CategoryModel>[];
    emit(WorkersLoading());
    try {
      final workers = await _service.getWorkers(categoryId: categoryId);
      emit(WorkersLoaded(categories: cats, workers: workers, selectedCategoryId: categoryId));
    } catch (e) {
      emit(WorkersError(e.toString()));
    }
  }
}
