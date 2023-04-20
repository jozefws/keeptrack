import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeConfigProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  SharedPreferences? sharedPreferences;

  ThemeConfigProvider() {
    getSharedPreferencesTheme();
  }

  // Initialize the theme mode
  ThemeConfigProvider.initial(ThemeMode mode) {
    themeMode = mode;
  }

  // Initialize shared preferences
  initSharedPreferences() async {
    sharedPreferences ??= await SharedPreferences.getInstance();
  }

  // Get the theme from shared preferences
  getSharedPreferencesTheme() async {
    await initSharedPreferences();
    themeMode = sharedPreferences!.getBool('theme/dark-mode') ?? false
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  // Set the theme in shared preferences
  setSharedPreferencesTheme(ThemeMode mode) async {
    themeMode = mode;
    await initSharedPreferences();
    sharedPreferences!.setBool('settings/dark-mode', mode == ThemeMode.dark);
    notifyListeners();
  }
}
