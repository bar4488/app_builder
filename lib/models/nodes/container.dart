import 'package:flutter/material.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/render_data.dart';
import 'package:unreal_editor/models/node_settigns.dart';
import 'package:unreal_editor/models/variable.dart';
import 'package:unreal_editor/state/blueprint_state.dart';
import 'package:unreal_editor/utils/colors.dart';

class ContainerNode extends Node {
  final RenderData _renderData = ContainerRenderData();

  @override
  RenderData get renderData => _renderData;

  final NodeSettigns _settigns = ContainerNodeSettigns();
  @override
  NodeSettigns get settings => _settigns;

  RenderTarget child = RenderTarget(
    name: "Child",
  );

  NodeVariable<Color?> color = NodeVariable<Color?>(
    name: "Color",
  );

  ContainerNode({required super.id, required super.position})
      : super(
          title: "Container",
          hasRenderInput: true,
        );

  @override
  Iterable<NodeVariable> getVariables() => [];

  @override
  Iterable<RenderTarget> getRenderTargets() => [
        child,
      ];
}

class ContainerRenderData extends RenderData<ContainerNode> {
  ContainerRenderData();

  @override
  Widget Function() getBuilder(
    BlueprintState state,
    ContainerNode node,
  ) {
    Widget child = node.child.build(state);

    Widget builder() {
      return Container(
        color: node.color.valueOrNull,
        child: child,
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
          enumValues: colors,
          prefixes: colors
              .map(
                (e) => CircleAvatar(
                  backgroundColor: e.value,
                  radius: 8,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
