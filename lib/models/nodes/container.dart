import 'package:app_builder/state/preview_state.dart';
import 'package:flutter/material.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/render_data.dart';
import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/variable.dart';
import 'package:app_builder/state/blueprint_state.dart';
import 'package:app_builder/utils/enums.dart';

class ContainerNode extends Node {
  @override
  String get typeName => "Container";
  final RenderData _renderData = ContainerRenderData();

  @override
  RenderData get renderData => _renderData;

  final NodeSettigns _settigns = ContainerNodeSettigns();
  @override
  NodeSettigns get settings => _settigns;

  RenderTarget child = RenderTarget(
    name: "Child",
    required: false,
  );

  NodeVariable<Color?> color = NodeVariable<Color?>(
    name: "Color",
    defaultValue: null,
  );

  NodeVariable<Alignment> alignment = NodeVariable<Alignment>(
    name: "Alignment",
    defaultValue: Alignment.center,
  );

  ContainerNode(
      {required super.id, required super.position, required super.blueprint})
      : super(
          hasRenderInput: true,
        );

  @override
  Iterable<NodeVariable> getVariables() => [alignment, color];

  @override
  Iterable<RenderTarget> getRenderTargets() => [
        child,
      ];
}

class ContainerRenderData extends RenderData<ContainerNode> {
  ContainerRenderData();

  @override
  Widget Function() getBuilder(
    PreviewState state,
    ContainerNode node,
  ) {
    Widget? child = node.child.tryBuild(state);

    Widget builder() {
      return Container(
        color: node.color.valueOrNull,
        child: child,
        alignment: node.alignment.value,
      );
    }

    return builder;
  }
}

class ContainerNodeSettigns extends NodeSettigns<ContainerNode> {
  @override
  Widget buildSettingsWidget(BuildContext context, ContainerNode node) {
    return ListView(
      children: [
        EnumValueEditor<Color?>(
          node: node,
          variable: node.color,
          enumType: Enums.color,
        ),
        EnumValueEditor<Alignment>(
          node: node,
          variable: node.alignment,
          enumType: Enums.alignment,
        ),
      ],
    );
  }
}
