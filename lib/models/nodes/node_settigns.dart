import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/nodes/node_data.dart';
import 'package:unreal_editor/state/blueprint_state.dart';

abstract class NodeSettigns<T extends Node> {
  Widget buildSettingsWidget(BuildContext context, T node);
}

class StringNodeSettigns extends NodeSettigns<StringNode> {
  String? value;
  StringNodeSettigns();

  Widget buildSettingsWidget(BuildContext context, StringNode node) {
    // build a widget to edit the string value
    return TextField(
      controller: TextEditingController(text: value),
      onChanged: (newValue) {
        value = newValue;
        if (value == null || value!.isEmpty) {
          node.valuePin.update(null);
        } else {
          node.valuePin.update(ConstValueNode(value!));
        }
        context.read<BlueprintState>().notifyListeners();
      },
      decoration: const InputDecoration(labelText: 'String Value'),
    );
  }
}
