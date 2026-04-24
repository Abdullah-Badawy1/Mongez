import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:mongez/core/helpers.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(BuildContext context)
    : super(
        ThemeState(
          themeMode: AppPrefs.getIsDarkMode(context)
              ? ThemeMode.dark
              : ThemeMode.light,
        ),
      );

  Future<void> toggleTheme() async {
    final isDark = state.themeMode == ThemeMode.dark;
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;

    emit(ThemeState(themeMode: newMode));
    await AppPrefs.setDarkMode(newMode == ThemeMode.dark);
  }

  Future<void> setTheme(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;

    emit(ThemeState(themeMode: newMode));
    await AppPrefs.setDarkMode(isDark);
  }
}
