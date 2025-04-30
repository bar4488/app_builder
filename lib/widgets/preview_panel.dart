import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/models/pin.dart';
import 'package:unreal_editor/state/blueprint_editor_state.dart';
import 'package:unreal_editor/state/blueprint_state.dart';

class PreviewPanel extends StatelessWidget {
  const PreviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<BlueprintState>();
    return state.postOrderWalk(
      state.viewportNode,
      pinType: PinType.render,
      action: (node, List<Widget> children) {
        // This is where you would handle the rendering logic
        // For now, we just print the node ID
        print('Rendering node: ${node.id} with children: $children');
        return node.getRenderer()!.buildNodeWidget(node, children);
      },
    );
  }
}
