import 'package:app_builder/models/pin.dart';
import 'package:flutter/material.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/nodes/column.dart';
import 'package:app_builder/models/nodes/row.dart';
import 'package:app_builder/models/nodes/const.dart';
import 'package:app_builder/models/nodes/text.dart';
import 'package:app_builder/models/nodes/viewport.dart';
import 'package:app_builder/models/nodes/container.dart';

export 'package:app_builder/models/nodes/column.dart';
export 'package:app_builder/models/nodes/row.dart';
export 'package:app_builder/models/nodes/const.dart';
export 'package:app_builder/models/nodes/text.dart';
export 'package:app_builder/models/nodes/viewport.dart';
export 'package:app_builder/models/nodes/container.dart';

enum NodeCategory {
  layout,
  widget,
  data,
  internal,
}

List<NodeType> nodeTypes = [
  NodeType(
    name: "Column",
    isRenderInput: true,
    isRenderOutput: true,
    category: NodeCategory.layout,
    icon: Icons.table_rows_sharp,
    nodeBuilder: (id, position) => ColumnNode(id: id, position: position),
  ),
  NodeType(
    name: "Row",
    isRenderInput: true,
    isRenderOutput: true,
    category: NodeCategory.layout,
    icon: Icons.view_column,
    nodeBuilder: (id, position) => RowNode(id: id, position: position),
  ),
  NodeType(
    name: "String",
    valueOutputTypes: [String],
    category: NodeCategory.data,
    icon: Icons.text_fields,
    nodeBuilder: (id, position) => StringNode(id: id, position: position),
  ),
  NodeType(
    name: "Text",
    isRenderInput: true,
    valueInputTypes: [String],
    icon: Icons.text_format,
    category: NodeCategory.widget,
    nodeBuilder: (id, position) => TextNode(id: id, position: position),
  ),
  NodeType(
    name: "Viewport",
    category: NodeCategory.internal,
    icon: Icons.view_in_ar,
    nodeBuilder: (id, position) => ViewportNode(id: id, position: position),
  ),
  NodeType(
    name: "Container",
    isRenderInput: true,
    isRenderOutput: true,
    category: NodeCategory.widget,
    nodeBuilder: (id, position) => ContainerNode(id: id, position: position),
  ),
];

class NodeType {
  final String name;
  final NodeCategory category;
  final IconData? icon;
  final Node Function(String id, Offset position) nodeBuilder;

  final bool isRenderInput;
  final List<Type> valueInputTypes;
  final bool isRenderOutput;
  final List<Type> valueOutputTypes;

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
        pin is OutputValuePin && valueInputTypes.contains(pin.valueType) ||
        pin is InputValuePin && valueOutputTypes.contains(pin.valueType));
  }
}
