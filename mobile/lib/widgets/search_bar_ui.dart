import 'package:flutter/material.dart';
import 'package:mongez/generated/l10n.dart';

class SearchFieldUI extends StatelessWidget {
  final String? hintText;
  final VoidCallback onTap;

  const SearchFieldUI({super.key, this.hintText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                theme.brightness == Brightness.dark ? 0.2 : 0.08,
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
              child: Text(
                hintText ?? lang.searchHint,
                style: textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
