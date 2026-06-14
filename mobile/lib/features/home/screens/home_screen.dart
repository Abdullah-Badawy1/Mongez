import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/categories/screens/categories_screen.dart';
import 'package:mongez/features/details/screens/details_view.dart';
import 'package:mongez/features/home/widgets/home_sliver_app_bar.dart';
import 'package:mongez/features/home/widgets/service_card.dart';
import 'package:mongez/features/home/widgets/custom_category_list.dart';
import 'package:mongez/features/auth/models/user.dart';
import 'package:mongez/features/search/presentation/screens/search_screen.dart';
import 'package:mongez/features/workers/presentation/cubit/workers_cubit.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_section.dart';
import 'package:mongez/widgets/search_bar_ui.dart';

class HomeScreen extends StatelessWidget {
  final bool isCustomer;
  final User user;
  const HomeScreen({super.key, required this.isCustomer, required this.user});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<WorkersCubit>().refresh(),
          child: CustomScrollView(
          slivers: [
            CustomSliverAppBarHome(user: user, isCustomer: isCustomer),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    SearchFieldUI(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchScreen(
                              isCustomer: isCustomer,
                            ),
                          ),
                        );
                      },
                    ),
                    isCustomer
                        ? CustomSection(
                            title: lang.category,
                            actionText: lang.viewAll,
                            onActionTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CategoriesScreen(
                                    isCustomer: isCustomer,
                                  ),
                                ),
                              );
                            },
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
            ),
            isCustomer
                ? SliverToBoxAdapter(child: CategoryList(isCustomer: isCustomer))
                : const SliverToBoxAdapter(child: SizedBox()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: CustomSection(
                  title: isCustomer ? lang.hotDeals : lang.myServices,
                ),
              ),
            ),
            BlocBuilder<WorkersCubit, WorkersState>(
              builder: (context, state) {
                if (state is WorkersLoading) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is WorkersFailure) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text(state.errorMessage)),
                  );
                }
                if (state is WorkersSuccess) {
                  final workers = state.workers;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final worker = workers[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailsView(
                                  worker: worker,
                                  isCustomer: isCustomer,
                                ),
                              ),
                            );
                          },
                          child: ServiceCard(
                            worker: worker,
                            isCustomer: isCustomer,
                          ),
                        ),
                      );
                    }, childCount: workers.length),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox());
              },
            ),
          ],
        ),
        ),
      ),
    );
  }
}
