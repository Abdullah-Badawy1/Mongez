import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/bloc/workers/workers_cubit.dart';
import 'package:mongez/core/bloc/workers/workers_state.dart';
import 'package:mongez/core/models/category_model.dart';
import 'package:mongez/core/models/worker_model.dart';
import 'package:mongez/features/home_feature/components/atoms/custom_app_bar.dart';
import 'package:mongez/features/home_feature/components/molecules/custom_category.dart';
import 'package:mongez/features/home_feature/components/molecules/service_istem_ui.dart';
import 'package:mongez/features/home_feature/model/category_model/datum.dart';
import 'package:mongez/features/home_feature/model/service_item/service_item.dart';
import 'package:mongez/features/details/presentation/views/details_view.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_section.dart';
import 'package:mongez/widgets/search_bar_ui.dart';

class HomeScreen extends StatelessWidget {
  final bool isCustomer;
  const HomeScreen({super.key, required this.isCustomer});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WorkersCubit()..load(),
      child: _HomeBody(isCustomer: isCustomer),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final bool isCustomer;
  const _HomeBody({required this.isCustomer});

  ServiceItem _workerToServiceItem(WorkerModel w, BuildContext context, int? categoryId) {
    final lang = S.of(context);
    return ServiceItem(
      title: w.profession,
      image: 'assets/images/E.png',
      cover: 'assets/images/EE.jpeg',
      workerImage: 'assets/images/person.png',
      description:
          '${w.profession} — ${w.experienceYears} years experience. Rating: ${w.averageRating.toStringAsFixed(1)}',
      comments: [lang.greatService, lang.veryProfessional],
      address: w.user.address.isNotEmpty ? w.user.address : lang.addressMainStreetCairo,
      workerId: w.user.id,
      categoryId: categoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);

    return BlocBuilder<WorkersCubit, WorkersState>(
      builder: (context, state) {
        final categories = state is WorkersLoaded ? state.categories : <CategoryModel>[];
        final workers = state is WorkersLoaded ? state.workers : <WorkerModel>[];
        final selectedCategoryId = state is WorkersLoaded ? state.selectedCategoryId : null;
        final categoryId = selectedCategoryId ?? (categories.isNotEmpty ? categories.first.id : null);

        final uiCategories = categories
            .map((c) => Categories(name: c.name, image: 'assets/images/E.png'))
            .toList();

        final services = workers.isNotEmpty
            ? workers.map((w) => _workerToServiceItem(w, context, categoryId)).toList()
            : _fallbackServices(lang);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                const CustomSliverAppBarHome(),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        SearchFieldUI(
                          onTap: () {
                            context
                                .read<WorkersCubit>()
                                .load();
                          },
                        ),
                        if (isCustomer)
                          CustomSection(
                            title: lang.category,
                            actionText: lang.viewAll,
                          ),
                      ],
                    ),
                  ),
                ),

                if (state is WorkersLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (state is WorkersError)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Could not load data. Showing sample content.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                if (isCustomer && uiCategories.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.width * 0.22,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: uiCategories.length,
                          itemBuilder: (_, i) => Padding(
                            padding: EdgeInsetsDirectional.only(
                                start: i == 0 ? 18 : 0),
                            child: GestureDetector(
                              onTap: () {
                                if (state is WorkersLoaded) {
                                  context
                                      .read<WorkersCubit>()
                                      .filterByCategory(
                                          state.categories[i].id);
                                }
                              },
                              child: CustomCategory(
                                  category: uiCategories[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: CustomSection(
                      title: isCustomer ? lang.hotDeals : lang.myServices,
                    ),
                  ),
                ),

                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final service = services[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailsView(
                                  item: service,
                                  isCustomer: isCustomer,
                                ),
                              ),
                            );
                          },
                          child: ServiceCard(
                            service: service,
                            isCustomer: isCustomer,
                          ),
                        ),
                      );
                    },
                    childCount: services.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<ServiceItem> _fallbackServices(S lang) => [
        ServiceItem(
          title: lang.electricFix,
          image: 'assets/images/E.png',
          cover: 'assets/images/EE.jpeg',
          workerImage: 'assets/images/person.png',
          description: lang.electricFixDescription,
          comments: [lang.greatService, lang.veryProfessional],
          address: lang.addressMainStreetCairo,
        ),
        ServiceItem(
          title: lang.plumbing,
          image: 'assets/images/E.png',
          cover: 'assets/images/BB.jpeg',
          workerImage: 'assets/images/person.png',
          description: lang.plumbingDescription,
          comments: [lang.fastAndReliable, lang.highlyRecommended],
          address: lang.addressNileStreetCairo,
        ),
      ];
}
