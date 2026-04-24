import 'package:flutter/material.dart';
import 'package:mongez/generated/l10n.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Image.asset(
              'assets/images/one.png',
              width: constraints.maxWidth > 400
                  ? 500
                  : constraints.maxWidth * 0.9,
              fit: BoxFit.contain,
            );
          },
        ),

        const SizedBox(height: 24),

        /// Title
        Text(
          lang.howItWorks,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),

        const SizedBox(height: 12),

        /// Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            lang.firstScreenDesc,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 18,
              height: 1.5,
              color: textTheme.bodyMedium?.color, // 👈 يخليها تمشي مع الدارك
            ),
          ),
        ),
      ],
    );
  }
}
