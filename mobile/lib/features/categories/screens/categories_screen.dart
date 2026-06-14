import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/home/bloc/categories_cubit/categories_cubit.dart';
import 'package:mongez/features/home/models/categories.dart';
import 'package:mongez/features/search/presentation/screens/search_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';

class CategoriesScreen extends StatelessWidget {
  final bool isCustomer;

  const CategoriesScreen({super.key, this.isCustomer = true});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: lang.category),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, state) {
          if (state is CategoriesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CategoriesFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.errorMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.tonal(
                    onPressed: () =>
                        context.read<CategoriesCubit>().fetchCategories(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is CategoriesSuccess) {
            final categories = state.categories;
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              itemCount: categories.length,
              itemBuilder: (_, index) => _CategoryCard(
                category: categories[index],
                isCustomer: isCustomer,
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoriesModel category;
  final bool isCustomer;

  const _CategoryCard({required this.category, required this.isCustomer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primaryContainer,
                        cs.primaryContainer.withValues(alpha: 0.55),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: category.imageUrl != null
                      ? Image.network(
                          category.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.category_rounded,
                            color: cs.primary,
                            size: 28,
                          ),
                        )
                      : Icon(
                          Icons.category_rounded,
                          color: cs.primary,
                          size: 28,
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  category.name ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tt.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
