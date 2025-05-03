import 'package:app_builder/state/blueprint_state.dart';
import 'package:flutter/material.dart';

class PreviewState with ChangeNotifier {
  // errors map
  final Map<String, String?> _nodeErrors = {};
  final BlueprintState blueprint;

  PreviewState(this.blueprint);

  String? getNodeError(String nodeId) {
    return _nodeErrors[nodeId];
  }

  void setNodeError(String nodeId, String? error) {
    _nodeErrors[nodeId] = error;
    notifyListeners();
  }

  void clearNodeErrors() {
    _nodeErrors.clear();
    notifyListeners();
  }
}
