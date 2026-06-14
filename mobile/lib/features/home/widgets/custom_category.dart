import 'package:flutter/material.dart';
import 'package:mongez/features/home/models/categories.dart';

class CustomCategory extends StatelessWidget {
  final CategoriesModel category;
  final VoidCallback? onTap;

  const CustomCategory({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final label = category.displayName(locale);

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 14),
      child: SizedBox(
        width: 84,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primaryContainer,
                        cs.primaryContainer.withValues(alpha: 0.55),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  child: category.imageUrl != null
                      ? Image.network(
                          category.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            category.iconData,
                            color: cs.onPrimaryContainer,
                            size: 30,
                          ),
                        )
                      : Icon(
                          category.iconData,
                          color: cs.onPrimaryContainer,
                          size: 30,
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
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
