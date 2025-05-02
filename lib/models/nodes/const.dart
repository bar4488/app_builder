import 'package:flutter/material.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/node_settigns.dart';
import 'package:unreal_editor/models/pin.dart';

class StringNode extends Node {
  NodeSettigns _settigns;
  @override
  NodeSettigns get settings => _settigns;

  late OutputValuePin<String> valuePin;

  StringNode({required super.id, required super.position})
      : _settigns = StringNodeSettigns(),
        super(
          title: "String",
          type: NodeType.static,
        ) {
    valuePin = OutputValuePin<String>(
      nodeId: id,
      label: "value",
    );
    addOutputPin(valuePin);
  }
}

class StringNodeSettigns extends NodeSettigns<StringNode> {
  String? value;
  StringNodeSettigns();

  @override
  Widget buildSettingsWidget(BuildContext context, StringNode node) {
    // build a widget to edit the string value
    return ListView(
      children: [
        StringValueEditor(pin: node.valuePin),
      ],
    );
  }
}
