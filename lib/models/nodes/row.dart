import 'package:app_builder/state/preview_state.dart';
import 'package:flutter/material.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/render_data.dart';
import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/pin.dart';
import 'package:app_builder/models/variable.dart';
import 'package:app_builder/state/blueprint_state.dart';

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

  @override
  Iterable<NodeVariable> getVariables() => [
        mainAxisAlignment,
        crossAxisAlignment,
      ];

  final NodeSettigns _settigns = RowNodeSettigns();
  @override
  NodeSettigns get settings => _settigns;

  RowNode(
      {required super.id, required super.position, required super.blueprint})
      : _renderData = RowRenderData(),
        super(
          title: "Row",
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
}

class RowRenderData extends RenderData<RowNode> {
  RowRenderData();

  @override
  Widget Function() getBuilder(
    PreviewState state,
    RowNode node,
  ) {
    List<Widget> children = node.children.nonNulls
        .map(
          (e) => state.blueprint.findNodeById(e)!,
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
          enumValues: MainAxisAlignment.values
              .map(
                (value) => MapEntry(
                  value.name,
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
                  value.name,
                  value,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
