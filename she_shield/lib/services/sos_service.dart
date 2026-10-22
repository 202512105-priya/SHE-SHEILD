import 'package:flutter/material.dart';

class SosService extends ChangeNotifier {
  bool _isSosActive = false;
  int _countdown = 5;

  bool get isSosActive => _isSosActive;
  int get countdown => _countdown;

  void triggerSos() {
    _isSosActive = true;
    _countdown = 5;
    notifyListeners();
  }

  void cancelSos() {
    _isSosActive = false;
    _countdown = 5;
    notifyListeners();
  }
}
