import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:mongez/core/helpers.dart';

part 'localization_state.dart';

class LocalizationCubit extends Cubit<LocalizationState> {
  LocalizationCubit()
    : super(LocalizationState(locale: Locale(AppPrefs.locale)));

  Future<void> changeLanguage(String langCode) async {
    emit(LocalizationState(locale: Locale(langCode)));
    await AppPrefs.setLocale(langCode);
  }
}
