import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/pin.dart';
import 'package:app_builder/models/variable.dart';
import 'package:app_builder/widgets/blueprint_variables_panel.dart';
import 'package:flutter/material.dart';
import 'package:runtime_type/runtime_type.dart';

class GetVariableNode extends Node {
  @override
  String get typeName => "Variable";
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
  })  : _settigns = GetVariableNodeSettigns(),
        super() {
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
  @override
  String get typeName => "SetVariable";
  BlueprintVariable variable;

  @override
  final NodeSettigns settings = SetVariableNodeSettings();

  late InputExecutionPin execPin;

  VariableType? variableType;
  late DynamicInputValuePin valuePin;
  ValueNode? valueNode;
  SetVariableNode({
    required super.id,
    required super.position,
    required super.blueprint,
    required this.variable,
  }) : super() {
    execPin = InputExecutionPin(
      nodeId: id,
      label: "Exec",
      // ignore: avoid_print
      onFire: (state) {
        variable.setValue(valueNode?.value);
      },
    );
    addInputPin(execPin);
    variable.addListener(didChangeType);
    valuePin = DynamicInputValuePin(
      nodeId: id,
      label: "value",
      onValueChanged: (newVal) {
        valueNode = newVal;
      },
    );
    addInputPin(valuePin);
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
      valuePin.onValueChanged?.call(null);
    }
  }
}

class SetVariableNodeSettings extends NodeSettigns<SetVariableNode> {
  @override
  Widget buildSettingsWidget(BuildContext context, SetVariableNode node) {
    return ListView(
      children: [],
    );
  }
}
