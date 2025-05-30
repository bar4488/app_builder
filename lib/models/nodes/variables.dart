import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/pin.dart';
import 'package:app_builder/models/variable.dart';
import 'package:app_builder/utils/enums.dart';
import 'package:app_builder/widgets/blueprint_variables_panel.dart';
import 'package:flutter/material.dart';
import 'package:runtime_type/runtime_type.dart';

class GetVariableNode extends Node {
  NodeSettigns _settigns;
  @override
  NodeSettigns get settings => _settigns;

  BlueprintVariable variable;

  VariableType? variableType;
  late DynamicOutputValuePin valuePin;

  GetVariableNode({
    required super.id,
    required super.position,
    required super.blueprint,
    required this.variable,
  }) : _settigns = GetVariableNodeSettigns(),
       super(title: "Variable", type: NodeKind.static) {
    variable.addListener(didChangeType);
    valuePin = DynamicOutputValuePin(nodeId: id, label: "value");
    addOutputPin(valuePin);
    didChangeType();
  }

  void didChangeType() {
    if (variableType != variable.type) {
      valuePin.setValueType(switch (variable.type) {
        VariableType.integer => RuntimeType<int>(),
        VariableType.double => RuntimeType<double>(),
        VariableType.string => RuntimeType<String>(),
        VariableType.boolean => RuntimeType<bool>(),
      });
      valuePin.update(variable.value);
    }
  }

  @override
  OutputValuePin? getOutputValuePin(RuntimeType type) {
    return null;
  }

  @override
  String? get description => "Get ${variable.name}";
}

class GetVariableNodeSettigns extends NodeSettigns<GetVariableNode> {
  Enum? value;
  GetVariableNodeSettigns();

  @override
  Widget buildSettingsWidget(BuildContext context, GetVariableNode node) {
    // build a widget to edit the string value
    return ListView(children: []);
  }
}

class SetVariableNode extends Node {
  NodeVariable<String> text = NodeVariable(name: "Text");

  @override
  final NodeSettigns settings = SetVariableNodeSettings();

  late InputExecutionPin execPin;
  late InputValuePin inputValuePin;
  SetVariableNode({
    required super.id,
    required super.position,
    required super.blueprint,
  }) : super(title: "SetVariable") {
    execPin = InputExecutionPin(
      nodeId: id,
      label: "Exec",
      // ignore: avoid_print
      onFire: (state) => print(text.value),
    );
    addInputPin(execPin);
  }

  @override
  Iterable<NodeVariable> getVariables() => [text];
}

class SetVariableNodeSettings extends NodeSettigns<SetVariableNode> {
  @override
  Widget buildSettingsWidget(BuildContext context, SetVariableNode node) {
    return ListView(
      children: [StringValueEditor(node: node, variable: node.text)],
    );
  }
}
