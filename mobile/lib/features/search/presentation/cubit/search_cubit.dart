import 'package:bloc/bloc.dart';
import 'package:mongez/features/workers/data/models/worker_model.dart';
import 'package:mongez/features/workers/domain/worker_repository.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final WorkerRepository workerRepository;

  SearchCubit({required this.workerRepository}) : super(SearchInitial());

  List<WorkerModel> _allWorkers = [];
  bool _hasMore = true;
  int _currentPage = 1;
  int? _categoryId;
  String? _search;
  double? _minRating;
  bool? _isAvailable;

  void reset() {
    _allWorkers = [];
    _hasMore = true;
    _currentPage = 1;
    _categoryId = null;
    _search = null;
    _minRating = null;
    _isAvailable = null;
    emit(SearchInitial());
  }

  void setCategory(int? categoryId) {
    _categoryId = categoryId;
    _currentPage = 1;
    _allWorkers = [];
    _hasMore = true;
    _search = '';
    _load();
  }

  void setSearch(String search) {
    _search = search;
    _currentPage = 1;
    _allWorkers = [];
    _hasMore = true;
    _load();
  }

  void setRating(double? rating) {
    _minRating = rating;
    _currentPage = 1;
    _allWorkers = [];
    _hasMore = true;
    _load();
  }

  void setAvailability(bool? isAvailable) {
    _isAvailable = isAvailable;
    _currentPage = 1;
    _allWorkers = [];
    _hasMore = true;
    _load();
  }

  void setFilters({int? categoryId, double? minRating, bool? isAvailable}) {
    _categoryId = categoryId;
    _minRating = minRating;
    _isAvailable = isAvailable;
    _currentPage = 1;
    _allWorkers = [];
    _hasMore = true;
    _load();
  }

  void clearFilters() {
    _categoryId = null;
    _minRating = null;
    _isAvailable = null;
    _currentPage = 1;
    _allWorkers = [];
    _hasMore = true;
    _load();
  }

  void loadMore() {
    if (!_hasMore || state is SearchLoading) return;
    _currentPage++;
    _load();
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _allWorkers = [];
    _hasMore = true;
    await _load();
  }

  int? get categoryId => _categoryId;
  String? get search => _search;
  double? get minRating => _minRating;
  bool? get isAvailable => _isAvailable;

  Future<void> _load() async {
    emit(SearchLoading());
    final result = await workerRepository.getWorkers(
      categoryId: _categoryId,
      search: _search,
      page: _currentPage,
    );
    result.fold(
      (failure) => emit(SearchFailure(failure.errorMessage)),
      (workers) {
        _allWorkers.addAll(workers);
        _hasMore = workers.length >= 20;
        emit(SearchSuccess(List.from(_allWorkers)));
      },
    );
  }
}
