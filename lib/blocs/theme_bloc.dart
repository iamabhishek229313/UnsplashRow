import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unsplash_row/utils/constants.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;

  ThemeState(this.themeMode) : assert(themeMode != null);

  @override
  List<Object> get props => [themeMode];
}

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

class ThemeChanged extends ThemeEvent {
  final bool value;

  ThemeChanged(this.value) : assert(value != null);

  @override
  List<Object> get props => [value];
}

class ThemeLoadStarted extends ThemeEvent {}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc(ThemeState initialState) : super(initialState);

  @override
  ThemeState get initialState => ThemeState(ThemeMode.dark);

  @override
  Stream<ThemeState> mapEventToState(ThemeEvent event) async* {
    if (event is ThemeLoadStarted) {
      yield* _mapThemeLoadStartedToState();
    } else if (event is ThemeChanged) {
      yield* _mapThemeChangedToState(event.value);
    }
  }

  Stream<ThemeState> _mapThemeLoadStartedToState() async* {
    final _prefs = await SharedPreferences.getInstance();
    final isDarkModeEnabled = _prefs.getBool(AppConstants.darkMode);

    if (isDarkModeEnabled == null) {
      _prefs.setBool(AppConstants.darkMode, true);
      yield ThemeState(ThemeMode.dark);
    } else {
      ThemeMode themeMode = isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light;
      yield ThemeState(themeMode);
    }
  }

  Stream<ThemeState> _mapThemeChangedToState(bool value) async* {
    final _prefs = await SharedPreferences.getInstance();
    final isDarkModeEnabled = _prefs.getBool(AppConstants.darkMode);

    if (value && isDarkModeEnabled == false) {
      await _prefs.setBool(AppConstants.darkMode, true);
      yield ThemeState(ThemeMode.dark);
    } else if (!value && isDarkModeEnabled == true) {
      await _prefs.setBool(AppConstants.darkMode, false);
      yield ThemeState(ThemeMode.light);
    }
  }
}
