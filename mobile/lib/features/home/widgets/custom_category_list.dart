import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/home/bloc/categories_cubit/categories_cubit.dart';
import 'package:mongez/features/home/widgets/custom_category.dart';
import 'package:mongez/features/search/presentation/screens/search_screen.dart';

class CategoryList extends StatelessWidget {
  final bool isCustomer;

  const CategoryList({super.key, this.isCustomer = true});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        if (state is CategoriesLoading) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CategoriesFailure) {
          return Center(child: Text(state.errorMessage));
        }

        if (state is CategoriesSuccess) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              height: width * 0.22,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.categories.length,
                itemBuilder: (_, index) {
                  final category = state.categories[index];
                  return index == 0
                      ? Padding(
                          padding: const EdgeInsetsDirectional.only(start: 18),
                          child: CustomCategory(
                            category: category,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SearchScreen(
                                    initialCategoryId: category.id,
                                    initialCategoryName: category.name,
                                    isCustomer: isCustomer,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : CustomCategory(
                          category: category,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SearchScreen(
                                  initialCategoryId: category.id,
                                  initialCategoryName: category.name,
                                  isCustomer: isCustomer,
                                ),
                              ),
                            );
                          },
                        );
                },
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
