import 'package:flutter/material.dart';
import 'package:flutter_gemini/theme/theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = LightMode;

  ThemeData get themeData => _themeData;

  set themeData (ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toogleTheme() {
    if (_themeData == LightMode) {
      _themeData = DarkMode;
    } else {
      _themeData = LightMode;
    }
    notifyListeners();
  }
}