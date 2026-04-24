import 'package:flutter/material.dart';
import 'package:mongez/features/login_feature/screens/on_board_screens/on_board_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_button.dart';
import 'package:mongez/widgets/logo.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen>
    with SingleTickerProviderStateMixin {
  bool startAnimation = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        startAnimation = true;
      });
    });
  }

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
            children: [
              const Spacer(),
              AnimatedSlide(
                offset: startAnimation ? Offset.zero : const Offset(0, 0.3),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: startAnimation ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: const Logo(),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedOpacity(
                opacity: startAnimation ? 1 : 0,
                duration: const Duration(milliseconds: 1000),
                child: Text(
                  lang.getStartedSubtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: startAnimation ? 1 : 0,
                duration: const Duration(milliseconds: 1200),
                child: Text(
                  lang.getStartedDescription,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
              const Spacer(),
              AnimatedScale(
                scale: startAnimation ? 1 : 0.8,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                child: CustomButton(
                  text: lang.getStartedButton,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const OnboardScreen()),
                    );
                  },
                  textColor: colorScheme.onPrimary,
                  backgroundColor: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: startAnimation ? 1 : 0,
                duration: const Duration(milliseconds: 1400),
                child: Text(
                  lang.getStartedFooter,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
