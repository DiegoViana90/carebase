import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Carrega o tema salvo para o userId anônimo
  Future<void> loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await UserService.getOrCreateUserId();

    final isDark = prefs.getBool('theme_$userId') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Altera e salva o tema vinculado ao userId
  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();
    final userId = await UserService.getOrCreateUserId();

    await prefs.setBool('theme_$userId', isDark);
    notifyListeners();
  }
}
