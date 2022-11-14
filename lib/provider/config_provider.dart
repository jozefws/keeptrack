import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeConfigProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  SharedPreferences? sharedPreferencess;

  ThemeConfigProvider() {
    getSharedPreferencesTheme();
  }

  ThemeConfigProvider.initial(ThemeMode mode) {
    themeMode = mode;
  }

  initSharedPreferences() async {
    sharedPreferencess ??= await SharedPreferences.getInstance();
  }

  getSharedPreferencesTheme() async {
    await initSharedPreferences();
    themeMode = sharedPreferencess!.getBool('theme/dark-mode') ?? false
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  setSharedPreferencesTheme(ThemeMode mode) async {
    themeMode = mode;
    await initSharedPreferences();
    sharedPreferencess!.setBool('settings/dark-mode', mode == ThemeMode.dark);
    notifyListeners();
  }
}
