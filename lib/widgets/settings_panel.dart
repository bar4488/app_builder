import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/state/blueprint_editor_state.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    var selectedNode = context.select<BlueprintEditorState, Node?>(
      (value) => value.selectedNode,
    );
    if (selectedNode == null) {
      return const Center(
        child: Text(
          "No node selected",
          style: TextStyle(color: Colors.white),
        ),
      );
    } else if (selectedNode.settings == null) {
      return const Center(
        child: Text(
          "No settings available",
          style: TextStyle(color: Colors.white),
        ),
      );
    } else {
      return selectedNode.settings!.buildSettingsWidget(
        context,
        selectedNode,
      );
    }
  }
}
