import 'package:app_builder/models/pin.dart';
import 'package:app_builder/state/preview_state.dart';
import 'package:flutter/material.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/render_data.dart';
import 'package:app_builder/models/variable.dart';

class AppBarNode extends Node {
  @override
  final RenderData renderData = AppBarRenderData();

  @override
  final NodeSettigns settings = AppBarNodeSettigns();

  RenderTarget titleWidget = RenderTarget(
    name: "Title",
  );

  AppBarNode(
      {required super.id, required super.position, required super.blueprint})
      : super(
          title: "AppBar",
          hasRenderInput: true,
        );

  @override
  Iterable<NodeVariable> getVariables() => [];

  @override
  Iterable<RenderTarget> getRenderTargets() => [titleWidget];

  @override
  OutputRenderPin? getOutputRenderPin() {
    return outputPins
        .whereType<OutputRenderPin>()
        .where((e) => e.label == titleWidget.name)
        .single;
  }
}

class AppBarRenderData extends RenderData<AppBarNode> {
  AppBarRenderData();

  @override
  Widget Function() getBuilder(
    PreviewState state,
    AppBarNode node,
  ) {
    Widget title = node.titleWidget.build(state);

    Widget builder() {
      return AppBar(
        title: title,
      );
    }

    return builder;
  }
}

class AppBarNodeSettigns extends NodeSettigns<AppBarNode> {
  @override
  Widget buildSettingsWidget(BuildContext context, AppBarNode node) {
    return ListView(
      children: const [],
    );
  }
}
