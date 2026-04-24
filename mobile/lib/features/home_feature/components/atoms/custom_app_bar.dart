import 'package:flutter/material.dart';
import 'package:mongez/generated/l10n.dart';

class CustomSliverAppBarHome extends StatelessWidget {
  const CustomSliverAppBarHome({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SliverAppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      pinned: false,
      floating: false,
      expandedHeight: 60,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.location,
                    style: textTheme.bodySmall?.copyWith(
                      color: textTheme.bodySmall?.color,
                    ),
                  ),
                  Text(
                    lang.currentLocation,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),

              /// Notification Icon
              GestureDetector(
                onTap: () {},
                child: Image.asset(
                  'assets/images/notifaction.png',
                  width: 40,
                  height: 40,
                  color: colorScheme.onSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
