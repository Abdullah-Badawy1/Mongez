import 'package:flutter/material.dart';
import 'package:mongez/core/helpers.dart';
import 'package:mongez/features/auth/screens/login_screen.dart';
import 'package:mongez/features/auth/screens/onboarding/first_screen.dart';
import 'package:mongez/features/auth/screens/onboarding/second_screen.dart';
import 'package:mongez/features/auth/screens/onboarding/third_screen.dart';
import 'package:mongez/features/auth/screens/onboarding/widgets/custom_indicator.dart';
import 'package:mongez/generated/l10n.dart';

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> {
  final PageController _controller = PageController();
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) {
                  setState(() {
                    index = value;
                  });
                },
                children: const [FirstScreen(), SecondScreen(), ThirdScreen()],
              ),
            ),

            /// Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: CustomIndicator(active: index == i),
                ),
              ),
            ),

            /// Buttons
            Padding(
              padding: const EdgeInsets.all(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  index <= 1
                      ? TextButton(
                          onPressed: () {
                            AppPrefs.setOnboardingSeen(true);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            lang.skip,
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        )
                      : const SizedBox(),

                  ElevatedButton(
                    onPressed: () {
                      if (index == 2) {
                        AppPrefs.setOnboardingSeen(true);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.linear,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      minimumSize: const Size(100, 50),
                    ),
                    child: Text(
                      index == 2 ? lang.login : lang.next,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

