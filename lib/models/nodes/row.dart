import 'package:flutter/material.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/render_data.dart';
import 'package:unreal_editor/models/node_settigns.dart';
import 'package:unreal_editor/models/pin.dart';
import 'package:unreal_editor/models/variable.dart';
import 'package:unreal_editor/state/blueprint_state.dart';

class RowNode extends MultiOutputNode {
  final RenderData _renderData;

  @override
  RenderData get renderData => _renderData;

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

  final NodeSettigns _settigns = RowNodeSettigns();
  @override
  NodeSettigns get settings => _settigns;

  RowNode({required super.id, required super.position})
      : _renderData = RowRenderData(),
        super(
          title: "Row",
        );

  @override
  void addOutputRenderPin() {
    children.add(null);
    var index = children.length - 1;
    addOutputPin(
      OutputRenderPin(
        nodeId: id,
        label: "Output ${outputPins.length + 1}",
        direction: PinDirection.output,
        onRenderTargetChanged: (nodeId) {
          children[index] = nodeId;
          notifyListeners();
        },
      ),
    );
  }
}

class RowRenderData extends RenderData<RowNode> {
  RowRenderData();

  @override
  Iterable<NodeVariable> getVariables(RowNode node) => [
        node.mainAxisAlignment,
        node.crossAxisAlignment,
      ];

  @override
  Widget Function() getBuilder(
    BlueprintState state,
    RowNode node,
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
        return Row(
          mainAxisAlignment: node.mainAxisAlignment.value,
          crossAxisAlignment: node.crossAxisAlignment.value,
          children: children,
        );
      });
    }

    return builder;
  }
}

class RowNodeSettigns extends NodeSettigns<RowNode> {
  @override
  Widget buildSettingsWidget(BuildContext context, RowNode node) {
    return ListView(
      children: [
        EnumValueEditor<MainAxisAlignment>(
          node: node,
          variable: node.mainAxisAlignment,
          enumValues: MainAxisAlignment.values.asMap().map(
                (key, value) => MapEntry(
                  value.toString(),
                  value,
                ),
              ),
        ),
        EnumValueEditor<CrossAxisAlignment>(
          node: node,
          variable: node.crossAxisAlignment,
          enumValues: CrossAxisAlignment.values.asMap().map(
                (key, value) => MapEntry(
                  value.toString(),
                  value,
                ),
              ),
        ),
      ],
    );
  }
}
