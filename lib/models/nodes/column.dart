import 'package:flutter/material.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/render_data.dart';
import 'package:unreal_editor/models/node_settigns.dart';
import 'package:unreal_editor/models/pin.dart';
import 'package:unreal_editor/models/variable.dart';
import 'package:unreal_editor/state/blueprint_state.dart';

class ColumnNode extends MultiOutputNode {
  final RenderData _renderData = ColumnRenderData();

  @override
  RenderData get renderData => _renderData;

  final NodeSettigns _settigns = ColumnNodeSettigns();
  @override
  NodeSettigns get settings => _settigns;

  final List<String?> children = [];

  NodeVariable<MainAxisAlignment> mainAxisAlignment =
      NodeVariable<MainAxisAlignment>(
    name: "MainAxisAlignment",
    defaultValue: MainAxisAlignment.start,
  );
  NodeVariable<CrossAxisAlignment> crossAxisAlignment =
      NodeVariable<CrossAxisAlignment>(
    name: "CrossAxisAlignment",
    defaultValue: CrossAxisAlignment.start,
  );

  ColumnNode({required super.id, required super.position})
      : super(
          title: "Column",
          hasRenderInput: true,
        );

  @override
  OutputRenderPin addOutputRenderPin() {
    children.add(null);
    var index = children.length - 1;
    var pin = OutputRenderPin(
      nodeId: id,
      label: "Output ${outputPins.length + 1}",
      onRenderTargetChanged: (nodeId) {
        children[index] = nodeId;
        notifyListeners();
      },
    );
    addOutputPin(pin);
    return pin;
  }

  @override
  Iterable<NodeVariable> getVariables() => [
        mainAxisAlignment,
        crossAxisAlignment,
      ];
}

class ColumnRenderData extends RenderData<ColumnNode> {
  ColumnRenderData();

  @override
  Widget Function() getBuilder(
    BlueprintState state,
    ColumnNode node,
  ) {
    List<Widget> children = node.children.nonNulls
        .map(
          (e) => state.findNodeById(e)!,
        )
        .map((child) => child.renderData!.build(state, child))
        .toList()
        .cast<Widget>();

    Widget builder() {
      return Builder(builder: (context) {
        return Column(
          mainAxisAlignment: node.mainAxisAlignment.value,
          crossAxisAlignment: node.crossAxisAlignment.value,
          children: children,
        );
      });
    }

    return builder;
  }
}

class ColumnNodeSettigns extends NodeSettigns<ColumnNode> {
  @override
  Widget buildSettingsWidget(BuildContext context, ColumnNode node) {
    return ListView(
      children: [
        EnumValueEditor<MainAxisAlignment>(
          node: node,
          variable: node.mainAxisAlignment,
          enumValues: MainAxisAlignment.values
              .map(
                (value) => MapEntry(
                  value.toString(),
                  value,
                ),
              )
              .toList(),
        ),
        EnumValueEditor<CrossAxisAlignment>(
          node: node,
          variable: node.crossAxisAlignment,
          enumValues: CrossAxisAlignment.values
              .map(
                (value) => MapEntry(
                  value.toString(),
                  value,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
