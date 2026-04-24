import 'package:flutter/material.dart';

class CustomSection extends StatelessWidget {
  final String title;
  final String? actionText;

  const CustomSection({super.key, required this.title, this.actionText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// Title
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textTheme.bodyLarge?.color,
            ),
          ),

          /// Action Text (optional)
          if (actionText != null)
            Text(
              actionText!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.primary, // 👈 ممكن تخليه primary أحلى
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
