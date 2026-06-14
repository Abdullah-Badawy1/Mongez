import 'package:flutter/material.dart';
import 'package:mongez/generated/l10n.dart';

class SearchFieldUI extends StatelessWidget {
  final String? hintText;
  final VoidCallback? onTap;

  const SearchFieldUI({super.key, this.hintText, this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 22,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hintText ?? lang.searchHint,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
              Container(width: 1, height: 22, color: cs.outline),
              const SizedBox(width: 12),
              Icon(Icons.tune_rounded, size: 22, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}
