import 'package:flutter/material.dart';
import 'package:mongez/features/home_feature/model/category_model/datum.dart';

class CustomCategory extends StatelessWidget {
  final Categories category;

  const CustomCategory({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final size = MediaQuery.of(context).size.width * 0.08;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 16), // 👈 RTL support
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant, // 👈 بدل categoryCard
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              category.image ?? "",
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            category.name ?? "",
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
