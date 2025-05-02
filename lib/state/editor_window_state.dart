import 'package:flutter/material.dart';

class EditorWindowState with ChangeNotifier {
  bool _leftDrawerOpen = true;
  bool _rightDrawerOpen = false;

  bool get leftDrawerOpen => _leftDrawerOpen;
  bool get rightDrawerOpen => _rightDrawerOpen;

  GlobalKey settingsPanelKey = GlobalKey();

  // open and close drawers
  void toggleLeftDrawer() {
    _leftDrawerOpen = !_leftDrawerOpen;
    notifyListeners();
  }

  void toggleRightDrawer() {
    _rightDrawerOpen = !_rightDrawerOpen;
    notifyListeners();
  }

  void openLeftDrawer() {
    _leftDrawerOpen = true;
    notifyListeners();
  }

  void openRightDrawer() {
    _rightDrawerOpen = true;
    notifyListeners();
  }

  void closeLeftDrawer() {
    _leftDrawerOpen = false;
    notifyListeners();
  }

  void closeRightDrawer() {
    _rightDrawerOpen = false;
    notifyListeners();
  }

  void focusNodeSettings() {
    if (settingsPanelKey.currentContext == null) {
      return;
    }
    var scope = FocusScope.of(settingsPanelKey.currentContext!);
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => scope.nextFocus(),
    );
  }
}
