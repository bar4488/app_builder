import 'package:app_builder/state/preview_state.dart';
import 'package:flutter/material.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/render_data.dart';
import 'package:app_builder/models/pin.dart';
import 'package:app_builder/state/blueprint_state.dart';

class ViewportNode extends Node {
  final RenderData _renderData;

  String? childId;

  ViewportNode(
      {required super.id, required super.position, required super.blueprint})
      : _renderData = ViewportRenderData(),
        super(
          title: "Viewport",
          type: NodeKind.static,
        ) {
    addOutputPin(
      OutputRenderPin(
        nodeId: id,
        label: "Render",
        onRenderTargetChanged: (childId) {
          this.childId = childId;
          notifyListeners();
        },
      ),
    );
  }

  @override
  RenderData get renderData => _renderData;
}

class ViewportRenderData extends RenderData<ViewportNode> {
  ViewportRenderData();

  @override
  Widget Function() getBuilder(
    PreviewState state,
    ViewportNode node,
  ) {
    var childId = node.childId;
    if (childId == null) {
      return () => const Center(child: Text("Empty Viewport"));
    }
    var child = state.blueprint.findNodeById(childId)!;

    Widget childWidget = child.renderData!.build(state, child);
    return () => Center(child: childWidget);
  }
}
