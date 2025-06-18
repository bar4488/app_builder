import 'package:app_builder/models/pin.dart';
import 'package:app_builder/state/preview_state.dart';
import 'package:app_builder/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/render_data.dart';
import 'package:app_builder/models/variable.dart';

class AppBarNode extends Node {
  @override
  String get typeName => "AppBar";
  @override
  final RenderData renderData = AppBarRenderData();

  @override
  final NodeSettigns settings = AppBarNodeSettigns();

  RenderTarget titleWidget = RenderTarget(
    name: "Title",
    required: false,
  );

  NodeVariable<Color?> color = NodeVariable(
    name: "Color",
  );

  AppBarNode(
      {required super.id, required super.position, required super.blueprint})
      : super(
          hasRenderInput: true,
        );

  @override
  Iterable<NodeVariable> getVariables() => [color];

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
    Widget? title = node.titleWidget.tryBuild(state);

    Widget builder() {
      return AppBar(
        title: title,
        backgroundColor: node.color.value,
      );
    }

    return builder;
  }
}

class AppBarNodeSettigns extends NodeSettigns<AppBarNode> {
  @override
  Widget buildSettingsWidget(BuildContext context, AppBarNode node) {
    return ListView(
      children: [
        EnumValueEditor<Color?>(
          node: node,
          variable: node.color,
          enumType: Enums.color,
        ),
      ],
    );
  }
}
