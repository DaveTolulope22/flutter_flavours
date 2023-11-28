import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  int _selectedDrawerIndex = 0;

  int get selectedDrawerIndex => _selectedDrawerIndex;

  set selectedDrawerIndex(int index) {
    _selectedDrawerIndex = index;
    notifyListeners();
  }
}
