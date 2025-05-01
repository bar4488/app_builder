import 'package:flutter/material.dart';
import 'package:unreal_editor/models/node.dart';

abstract class NodeSettigns<T extends Node> with ChangeNotifier {
  Widget buildSettingsWidget(T node);
}

class StringNodeSettigns extends NodeSettigns<StringNode> {
  String value;
  StringNodeSettigns(this.value);

  Widget buildSettingsWidget(StringNode node) {
    // build a widget to edit the string value
    return TextField(
      controller: TextEditingController(text: value),
      onChanged: (newValue) {
        value = newValue;
        notifyListeners();
      },
      decoration: const InputDecoration(labelText: 'String Value'),
    );
  }
}
