import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mongez/core/app_themes/app_themes.dart';
import 'package:mongez/core/bloc/cubit/localization_cubit.dart';
import 'package:mongez/core/bloc/theme_cubit/theme_cubit.dart';
import 'package:mongez/core/helpers.dart';
import 'package:mongez/features/login_feature/screens/get_started_screen.dart';
import 'package:mongez/features/main_screen/main_screen.dart';
import 'package:mongez/generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPrefs.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit(context)),
            BlocProvider(create: (_) => LocalizationCubit()),
          ],
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return BlocBuilder<LocalizationCubit, LocalizationState>(
                builder: (context, localeState) {
                  final isLoggedIn = AppPrefs.isLoggedIn;
                  final isWorker = AppPrefs.userRole == 'worker';

                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppThemes.lightTheme,
                    darkTheme: AppThemes.darkTheme,
                    themeMode: themeState.themeMode,
                    locale: localeState.locale,
                    localizationsDelegates: [
                      S.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: S.delegate.supportedLocales,
                    home: isLoggedIn
                        ? MainScreen(isCustomer: !isWorker)
                        : const GetStartedScreen(),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
