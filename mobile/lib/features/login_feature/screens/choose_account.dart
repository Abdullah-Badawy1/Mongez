import 'package:flutter/material.dart';
import 'package:mongez/features/login_feature/screens/login_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_button.dart';
import 'package:mongez/widgets/logo.dart';

class ChooseAccountTypeScreen extends StatelessWidget {
  const ChooseAccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              /// App Logo
              const Logo(),
              const Spacer(),

              /// Main Title
              Text(
                lang.welcome,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 16),

              /// Subtitle
              Text(
                lang.chooseAccountSubtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 18,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              /// Customer Button
              CustomButton(
                text: lang.customer,
                backgroundColor: colorScheme.primary,
                textColor: colorScheme.onPrimary,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(isCustomer: true),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              /// Technician Button
              CustomButton(
                borderColor: colorScheme.primary,
                hasBorder: true,
                text: lang.technician,
                backgroundColor: theme.cardColor,
                textColor: colorScheme.primary,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(isCustomer: false),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              /// Footer Note
              Text(
                lang.chooseAccountFooter,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
