import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeConfigProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  SharedPreferences? sharedPreferences;

  ThemeConfigProvider() {
    getSharedPreferencesTheme();
  }

  ThemeConfigProvider.initial(ThemeMode mode) {
    themeMode = mode;
  }

  initSharedPreferences() async {
    sharedPreferences ??= await SharedPreferences.getInstance();
  }

  getSharedPreferencesTheme() async {
    await initSharedPreferences();
    themeMode = sharedPreferences!.getBool('theme/dark-mode') ?? false
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  setSharedPreferencesTheme(ThemeMode mode) async {
    themeMode = mode;
    await initSharedPreferences();
    sharedPreferences!.setBool('settings/dark-mode', mode == ThemeMode.dark);
    notifyListeners();
  }
}
