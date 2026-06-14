import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:mongez/features/workers/data/models/worker_model.dart';
import 'package:mongez/features/workers/domain/worker_repository.dart';

part 'workers_state.dart';

class WorkersCubit extends Cubit<WorkersState> {
  final WorkerRepository workerRepository;

  WorkersCubit({required this.workerRepository}) : super(WorkersInitial());

  List<WorkerModel> _allWorkers = [];
  bool _hasMore = true;
  int _currentPage = 1;
  int? _categoryId;
  String? _search;

  void reset() {
    _allWorkers = [];
    _hasMore = true;
    _currentPage = 1;
    _categoryId = null;
    _search = null;
    emit(WorkersInitial());
  }

  void setCategory(int? categoryId) {
    _categoryId = categoryId;
    _currentPage = 1;
    _allWorkers = [];
    _hasMore = true;
    _load();
  }

  void setSearch(String search) {
    _search = search;
    _currentPage = 1;
    _allWorkers = [];
    _hasMore = true;
    _load();
  }

  void loadMore() {
    if (!_hasMore || state is WorkersLoading) return;
    _currentPage++;
    _load();
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _allWorkers = [];
    _hasMore = true;
    await _load();
  }

  Future<void> _load() async {
    emit(WorkersLoading());
    final result = await workerRepository.getWorkers(
      categoryId: _categoryId,
      search: _search,
      page: _currentPage,
    );
    result.fold(
      (failure) => emit(WorkersFailure(failure.errorMessage)),
      (workers) {
        _allWorkers.addAll(workers);
        _hasMore = workers.length >= 20;
        emit(WorkersSuccess(List.from(_allWorkers)));
      },
    );
  }
}
