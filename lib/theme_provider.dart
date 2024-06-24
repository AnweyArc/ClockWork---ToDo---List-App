import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isNightMode = false;

  bool get isNightMode => _isNightMode;

  ThemeMode get currentTheme => _isNightMode ? ThemeMode.dark : ThemeMode.light;

  void toggleNightMode(bool isNightMode) {
    _isNightMode = isNightMode;
    notifyListeners();
  }
}
