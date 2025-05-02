import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/models/render_data.dart';
import 'package:unreal_editor/state/blueprint_editor_state.dart';
import 'package:unreal_editor/state/blueprint_state.dart';

class PreviewPanel extends StatefulWidget {
  const PreviewPanel({super.key});

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  Widget? child;

  @override
  void initState() {
    var state = context.read<BlueprintState>();
    state.addListener(onChangeBlueprintState);
    super.initState();
  }

  void onChangeBlueprintState() {
    var editorState = context.read<BlueprintEditorState>();
    var state = context.read<BlueprintState>();
    setState(() {
      editorState.clearNodeErrors();
      try {
        child = state.viewportNode.renderData!.build(state, state.viewportNode);
      } on NodeValueException catch (e) {
        editorState.setNodeError(e.nodeId, e.errorMessage);
        child = Center(
          child: Text(
            "No preview available: ${e.toString()}",
            style: const TextStyle(color: Colors.white),
          ),
        );
      } on NodeRenderException catch (e) {
        editorState.setNodeError(e.nodeId, e.errorMessage);
        child = Center(
          child: Text(
            "No preview available: ${e.toString()}",
            style: const TextStyle(color: Colors.white),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    var state = context.read<BlueprintState>();
    state.removeListener(onChangeBlueprintState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return child!;
    }
    return const Center(
      child: Text(
        "No preview available",
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
