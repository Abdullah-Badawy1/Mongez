import 'package:mongez/core/models/category_model.dart';
import 'package:mongez/core/models/worker_model.dart';

abstract class WorkersState {}

class WorkersInitial extends WorkersState {}

class WorkersLoading extends WorkersState {}

class WorkersLoaded extends WorkersState {
  final List<CategoryModel> categories;
  final List<WorkerModel> workers;
  final int? selectedCategoryId;
  WorkersLoaded({required this.categories, required this.workers, this.selectedCategoryId});
}

class WorkersError extends WorkersState {
  final String message;
  WorkersError(this.message);
}
