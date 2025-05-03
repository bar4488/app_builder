import 'package:app_builder/state/preview_state.dart';
import 'package:app_builder/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/render_data.dart';
import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/pin.dart';
import 'package:app_builder/models/variable.dart';

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

  ColumnNode(
      {required super.id, required super.position, required super.blueprint})
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
    PreviewState state,
    ColumnNode node,
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
          enumType: Enums.mainAxisAlignment,
        ),
        EnumValueEditor<CrossAxisAlignment>(
          node: node,
          variable: node.crossAxisAlignment,
          enumType: Enums.crossAxisAlignment,
        ),
      ],
    );
  }
}
