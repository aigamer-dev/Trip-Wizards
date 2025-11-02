import 'package:flutter/foundation.dart';

class AppBarTitleController extends ChangeNotifier {
  AppBarTitleController._();
  static final AppBarTitleController instance = AppBarTitleController._();

  String? _override;
  String? get override => _override;

  void setOverride(String? title) {
    if (_override == title) return;
    _override = title;
    notifyListeners();
  }
}
