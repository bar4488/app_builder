import 'dart:math';

import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/pin.dart';
import 'package:app_builder/models/variable.dart';
import 'package:app_builder/utils/enums.dart';
import 'package:app_builder/utils/let.dart';
import 'package:flutter/material.dart';
import 'package:runtime_type/runtime_type.dart';

class EnumNode extends Node {
  NodeSettigns _settigns;
  @override
  NodeSettigns get settings => _settigns;

  NodeVariable<EnumType> enumType = NodeVariable(
    name: "Type",
  );
  NodeVariable<EnumType> isNullable = NodeVariable(
    name: "Is Nullable",
  );
  NodeVariable<Object> enumValue = NodeVariable(
    name: "Value",
  );

  late DynamicOutputValuePin valuePin;

  EnumNode(
      {required super.id, required super.position, required super.blueprint})
      : _settigns = EnumNodeSettigns(),
        super(
          title: "Enum",
          type: NodeKind.static,
        ) {
    valuePin = DynamicOutputValuePin(
      nodeId: id,
      label: "value",
    );
    addOutputPin(valuePin);
    enumType.setOnChanged((newType) {
      blueprint.removeConnectionsForPin(valuePin);
      valuePin.setValueType(newType?.value.type ?? RuntimeType<void>());
      notifyListeners();
    });
    enumValue.setOnChanged((value) {
      valuePin.update(value);
      notifyListeners();
    });
  }

  @override
  OutputValuePin? getOutputValuePin(RuntimeType type) {
    enumType.setValueNode(
      ConstValueNode(
        Enums.types.enumValues
            .map((e) => e.value)
            .singleWhere((e) => e.type.isSubtypeOf(type)),
      ),
    );
    return valuePin;
  }

  @override
  String? get description => enumType.valueOrNull?.name ?? "Enum";
}

class EnumNodeSettigns extends NodeSettigns<EnumNode> {
  Enum? value;
  EnumNodeSettigns();

  @override
  Widget buildSettingsWidget(BuildContext context, EnumNode node) {
    // build a widget to edit the string value
    var enumType = node.enumType.valueOrNull;
    return ListView(
      children: [
        EnumValueEditor(
          node: node,
          variable: node.enumType,
          enumValues: Enums.types.enumValues,
        ),
        if (enumType != null)
          EnumValueEditor<Object>(
            key: ValueKey(enumType),
            node: node,
            variable: node.enumValue,
            enumValues: enumType.enumValues.cast(),
          ),
      ],
    );
  }
}
