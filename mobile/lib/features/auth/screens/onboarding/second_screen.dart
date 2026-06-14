import 'package:flutter/material.dart';
import 'package:mongez/generated/l10n.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

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
              'assets/images/two.png',
              width: constraints.maxWidth > 400
                  ? 500
                  : constraints.maxWidth * 0.9,
              fit: BoxFit.contain,
            );
          },
        ),

        const SizedBox(height: 24),

        Text(
          lang.trustedServices,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            lang.secondScreenDesc,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 18,
              height: 1.5,
              color: textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }
}
