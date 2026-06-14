import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/details/screens/details_view.dart';
import 'package:mongez/features/home/widgets/service_card.dart';
import 'package:mongez/features/search/presentation/cubit/search_cubit.dart';
import 'package:mongez/features/search/presentation/widgets/filter_sheet.dart';
import 'package:mongez/features/workers/domain/worker_repository.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/services/services_locator.dart';

class SearchScreen extends StatelessWidget {
  final int? initialCategoryId;
  final String? initialCategoryName;
  final bool isCustomer;

  const SearchScreen({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
    this.isCustomer = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchCubit(workerRepository: getIt.get<WorkerRepository>()),
      child: _SearchScreenBody(
        initialCategoryId: initialCategoryId,
        initialCategoryName: initialCategoryName,
        isCustomer: isCustomer,
      ),
    );
  }
}

class _SearchScreenBody extends StatefulWidget {
  final int? initialCategoryId;
  final String? initialCategoryName;
  final bool isCustomer;

  const _SearchScreenBody({
    this.initialCategoryId,
    this.initialCategoryName,
    this.isCustomer = true,
  });

  @override
  State<_SearchScreenBody> createState() => _SearchScreenBodyState();
}

class _SearchScreenBodyState extends State<_SearchScreenBody> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<SearchCubit>().setCategory(widget.initialCategoryId);
        }
      });
    }
  }

  void _onScroll() {
    final cubit = context.read<SearchCubit>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      cubit.loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    context.read<SearchCubit>().setSearch(value);
  }

  Future<void> _showFilters() async {
    final cubit = context.read<SearchCubit>();
    final result = await showFilterSheet(
      context,
      initialCategoryId: cubit.categoryId,
      initialMinRating: cubit.minRating,
      initialIsAvailable: cubit.isAvailable,
    );
    if (result != null && context.mounted) {
      cubit.setFilters(
        categoryId: result.categoryId,
        minRating: result.minRating,
        isAvailable: result.isAvailable,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          widget.initialCategoryName ?? lang.searchHint,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: theme.brightness == Brightness.dark ? 0.2 : 0.08,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/search.png',
                          width: 24,
                          height: 24,
                          color: textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: lang.searchHint,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: textTheme.bodyMedium?.copyWith(fontSize: 16),
                            onSubmitted: _onSearch,
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                            child: Icon(Icons.close, size: 20, color: textTheme.bodySmall?.color),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _showFilters,
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.tune,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state is SearchInitial) {
                  return Center(
                    child: Text(
                      'Search for workers and services',
                      style: textTheme.bodyMedium?.copyWith(
                        color: textTheme.bodySmall?.color,
                      ),
                    ),
                  );
                }
                if (state is SearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SearchFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.errorMessage, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<SearchCubit>().refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is SearchSuccess) {
                  final workers = state.workers;
                  if (workers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No results found',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => context.read<SearchCubit>().refresh(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: workers.length,
                      itemBuilder: (context, index) {
                        final worker = workers[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailsView(
                                    worker: worker,
                                    isCustomer: widget.isCustomer,
                                  ),
                                ),
                              );
                            },
                            child: ServiceCard(
                              worker: worker,
                              isCustomer: widget.isCustomer,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}
