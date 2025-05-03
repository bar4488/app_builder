import 'package:app_builder/models/nodes/app_bar.dart';
import 'package:app_builder/models/nodes/debug_print.dart';
import 'package:app_builder/models/nodes/enum_node.dart';
import 'package:app_builder/models/nodes/gesture_detector.dart';
import 'package:app_builder/models/nodes/scaffold.dart';
import 'package:app_builder/models/pin.dart';
import 'package:app_builder/state/blueprint_state.dart';
import 'package:app_builder/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/nodes/column.dart';
import 'package:app_builder/models/nodes/row.dart';
import 'package:app_builder/models/nodes/const.dart';
import 'package:app_builder/models/nodes/text.dart';
import 'package:app_builder/models/nodes/viewport.dart';
import 'package:app_builder/models/nodes/container.dart';
import 'package:runtime_type/runtime_type.dart';

enum NodeCategory {
  layout,
  widget,
  data,
  internal,
  debug,
  events,
}

List<NodeType> nodeTypes = [
  NodeType(
    name: "Scaffold",
    isRenderInput: true,
    isRenderOutput: true,
    category: NodeCategory.layout,
    nodeBuilder: (id, position, blueprint) =>
        ScaffoldNode(id: id, position: position, blueprint: blueprint),
  ),
  NodeType(
    name: "App Bar",
    isRenderInput: true,
    isRenderOutput: true,
    category: NodeCategory.layout,
    nodeBuilder: (id, position, blueprint) =>
        AppBarNode(id: id, position: position, blueprint: blueprint),
  ),
  NodeType(
    name: "Column",
    isRenderInput: true,
    isRenderOutput: true,
    category: NodeCategory.layout,
    icon: Icons.table_rows_sharp,
    nodeBuilder: (id, position, blueprint) =>
        ColumnNode(id: id, position: position, blueprint: blueprint),
  ),
  NodeType(
    name: "Row",
    isRenderInput: true,
    isRenderOutput: true,
    category: NodeCategory.layout,
    icon: Icons.view_column,
    nodeBuilder: (id, position, blueprint) =>
        RowNode(id: id, position: position, blueprint: blueprint),
  ),
  NodeType(
    name: "String",
    valueOutputTypes: [RuntimeType<String>()],
    category: NodeCategory.data,
    icon: Icons.text_fields,
    nodeBuilder: (id, position, blueprint) =>
        StringNode(id: id, position: position, blueprint: blueprint),
  ),
  NodeType(
    name: "Enum",
    valueOutputTypes: Enums.types.enumValues.map((e) => e.value.type).toList(),
    category: NodeCategory.data,
    nodeBuilder: (id, position, blueprint) =>
        EnumNode(id: id, position: position, blueprint: blueprint),
  ),
  NodeType(
    name: "Text",
    isRenderInput: true,
    valueInputTypes: Enums.types.enumValues.map((e) => e.value.type).toList(),
    icon: Icons.text_format,
    category: NodeCategory.widget,
    nodeBuilder: (id, position, blueprint) =>
        TextNode(id: id, position: position, blueprint: blueprint),
  ),
  NodeType(
    name: "Viewport",
    category: NodeCategory.internal,
    icon: Icons.view_in_ar,
    nodeBuilder: (id, position, blueprint) =>
        ViewportNode(id: id, position: position, blueprint: blueprint),
  ),
  NodeType(
    name: "Container",
    isRenderInput: true,
    isRenderOutput: true,
    category: NodeCategory.widget,
    nodeBuilder: (id, position, blueprint) =>
        ContainerNode(id: id, position: position, blueprint: blueprint),
  ),
  NodeType(
    name: "DebugPrint",
    isRenderInput: true,
    isRenderOutput: true,
    category: NodeCategory.debug,
    nodeBuilder: (id, position, blueprint) =>
        DebugPrintNode(id: id, position: position, blueprint: blueprint),
  ),
  NodeType(
    name: "GestureDetector",
    isRenderInput: true,
    isRenderOutput: true,
    category: NodeCategory.events,
    nodeBuilder: (id, position, blueprint) =>
        GestureDetectorNode(id: id, position: position, blueprint: blueprint),
  ),
];

class NodeType {
  final String name;
  final NodeCategory category;
  final IconData? icon;
  final Node Function(String id, Offset position, BlueprintState state)
      nodeBuilder;

  final bool isRenderInput;
  final List<RuntimeType> valueInputTypes;
  final bool isRenderOutput;
  final List<RuntimeType> valueOutputTypes;

  const NodeType({
    required this.name,
    this.icon,
    required this.category,
    required this.nodeBuilder,
    this.isRenderInput = false,
    this.valueInputTypes = const [],
    this.isRenderOutput = false,
    this.valueOutputTypes = const [],
  });

  bool canConnectTo(Pin pin) {
    return (pin is OutputRenderPin && isRenderInput ||
        pin is InputRenderPin && isRenderOutput ||
        pin is OutputValuePin &&
            valueInputTypes.any((e) => pin.valueType.isSubtypeOf(e)) ||
        pin is InputValuePin &&
            valueOutputTypes.any((e) => e.isSubtypeOf(pin.valueType)));
  }
}
