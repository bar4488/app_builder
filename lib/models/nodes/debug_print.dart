import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/pin.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/variable.dart';
import 'package:flutter/material.dart';

class DebugPrintNode extends Node {
  @override
  String get typeName => "DebugPrint";
  NodeVariable<String> text = NodeVariable(
    name: "Text",
  );

  @override
  final NodeSettigns settings = DebugPrintNodeSettings();

  late InputExecutionPin onTap;
  DebugPrintNode(
      {required super.id, required super.position, required super.blueprint})
      : super() {
    addInputPin(
      InputExecutionPin(
        nodeId: id,
        label: "On Tap",
        // ignore: avoid_print
        onFire: (state) => print(text.value),
      ),
    );
  }

  @override
  Iterable<NodeVariable> getVariables() => [text];
}

class DebugPrintNodeSettings extends NodeSettigns<DebugPrintNode> {
  @override
  Widget buildSettingsWidget(BuildContext context, DebugPrintNode node) {
    return ListView(
      children: [
        StringValueEditor(
          node: node,
          variable: node.text,
        ),
      ],
    );
  }
}
