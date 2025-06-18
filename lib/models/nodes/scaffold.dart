import 'package:app_builder/models/pin.dart';
import 'package:app_builder/state/preview_state.dart';
import 'package:flutter/material.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/render_data.dart';
import 'package:app_builder/models/variable.dart';

class ScaffoldNode extends Node {
  @override
  String get typeName => "Scaffold";
  @override
  final RenderData renderData = ScaffoldRenderData();

  @override
  final NodeSettigns settings = ScaffoldNodeSettigns();

  RenderTarget appBar = RenderTarget(
    name: "App Bar",
    required: false,
  );

  RenderTarget body = RenderTarget(
    name: "Body",
  );

  ScaffoldNode(
      {required super.id, required super.position, required super.blueprint})
      : super(
          hasRenderInput: true,
        );

  @override
  Iterable<NodeVariable> getVariables() => [];

  @override
  Iterable<RenderTarget> getRenderTargets() => [appBar, body];

  @override
  OutputRenderPin? getOutputRenderPin() {
    return outputPins
        .whereType<OutputRenderPin>()
        .where((e) => e.label == body.name)
        .single;
  }
}

class ScaffoldRenderData extends RenderData<ScaffoldNode> {
  ScaffoldRenderData();

  @override
  Widget Function() getBuilder(
    PreviewState state,
    ScaffoldNode node,
  ) {
    Widget? appBar = node.appBar.tryBuild(state);
    Widget body = node.body.build(state);

    Widget builder() {
      return Scaffold(
        body: body,
        appBar: appBar == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: appBar,
              ),
      );
    }

    return builder;
  }
}

class ScaffoldNodeSettigns extends NodeSettigns<ScaffoldNode> {
  @override
  Widget buildSettingsWidget(BuildContext context, ScaffoldNode node) {
    return ListView(
      children: const [],
    );
  }
}
