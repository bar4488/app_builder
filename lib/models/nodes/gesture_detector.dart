import 'package:app_builder/models/pin.dart';
import 'package:app_builder/state/preview_state.dart';
import 'package:flutter/material.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/render_data.dart';
import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/variable.dart';

class GestureDetectorNode extends Node {
  final RenderData _renderData = GestureDetectorRenderData();

  @override
  RenderData get renderData => _renderData;

  final NodeSettigns _settigns = GestureDetectorNodeSettigns();
  @override
  NodeSettigns get settings => _settigns;

  RenderTarget child = RenderTarget(
    name: "Child",
    required: false,
  );

  late OutputExecutionPin onTap;
  GestureDetectorNode(
      {required super.id, required super.position, required super.blueprint})
      : super(
          title: "GestureDetector",
          hasRenderInput: true,
        ) {
    onTap = OutputExecutionPin(
      nodeId: id,
      label: "On Tap",
    );
    addOutputPin(onTap);
  }

  @override
  Iterable<NodeVariable> getVariables() => [];

  @override
  Iterable<RenderTarget> getRenderTargets() => [
        child,
      ];
}

class GestureDetectorRenderData extends RenderData<GestureDetectorNode> {
  GestureDetectorRenderData();

  @override
  Widget Function() getBuilder(
    PreviewState state,
    GestureDetectorNode node,
  ) {
    Widget? child = node.child.tryBuild(state);

    Widget builder() {
      return GestureDetector(
        child: child,
        onTap: () => node.onTap.fire(state),
      );
    }

    return builder;
  }
}

class GestureDetectorNodeSettigns extends NodeSettigns<GestureDetectorNode> {
  @override
  Widget buildSettingsWidget(BuildContext context, GestureDetectorNode node) {
    return ListView(
      children: [],
    );
  }
}
