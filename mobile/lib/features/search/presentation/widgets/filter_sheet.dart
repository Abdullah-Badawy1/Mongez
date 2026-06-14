import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/home/bloc/categories_cubit/categories_cubit.dart';

class FilterResult {
  final int? categoryId;
  final double? minRating;
  final bool? isAvailable;

  const FilterResult({this.categoryId, this.minRating, this.isAvailable});
}

Future<FilterResult?> showFilterSheet(
  BuildContext context, {
  int? initialCategoryId,
  double? initialMinRating,
  bool? initialIsAvailable,
}) {
  return showModalBottomSheet<FilterResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FilterSheet(
      initialCategoryId: initialCategoryId,
      initialMinRating: initialMinRating,
      initialIsAvailable: initialIsAvailable,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  final int? initialCategoryId;
  final double? initialMinRating;
  final bool? initialIsAvailable;

  const _FilterSheet({
    this.initialCategoryId,
    this.initialMinRating,
    this.initialIsAvailable,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int? _selectedCategoryId;
  double _minRating = 0;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _minRating = widget.initialMinRating ?? 0;
    _isAvailable = widget.initialIsAvailable ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Filter', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Category
          Text('Category', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          BlocBuilder<CategoriesCubit, CategoriesState>(
            builder: (context, state) {
              if (state is! CategoriesSuccess) {
                return const SizedBox();
              }
              final categories = state.categories;
              return SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final isAll = index == 0;
                    final cat = isAll ? null : categories[index - 1];
                    final isSelected = isAll
                        ? _selectedCategoryId == null
                        : _selectedCategoryId == cat!.id;
                    return FilterChip(
                      label: Text(isAll ? 'All' : (cat?.name ?? '')),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategoryId = isAll ? null : cat!.id;
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Rating filter
          Text('Minimum Rating', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: _minRating.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _minRating = v),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  _minRating.toStringAsFixed(1),
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Availability
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Available only', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
          ),
          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(
                context,
                FilterResult(
                  categoryId: _selectedCategoryId,
                  minRating: _minRating > 0 ? _minRating : null,
                  isAvailable: _isAvailable ? true : null,
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
