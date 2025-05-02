import 'package:flutter/material.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/nodes/column.dart';
import 'package:unreal_editor/models/nodes/row.dart';
import 'package:unreal_editor/models/nodes/const.dart';
import 'package:unreal_editor/models/nodes/text.dart';
import 'package:unreal_editor/models/nodes/viewport.dart';
import 'package:unreal_editor/models/nodes/container.dart';

export 'package:unreal_editor/models/nodes/column.dart';
export 'package:unreal_editor/models/nodes/row.dart';
export 'package:unreal_editor/models/nodes/const.dart';
export 'package:unreal_editor/models/nodes/text.dart';
export 'package:unreal_editor/models/nodes/viewport.dart';
export 'package:unreal_editor/models/nodes/container.dart';

enum NodeCategory {
  layout,
  widget,
  data,
  internal,
}

List<NodeType> nodeTypes = [
  NodeType(
    name: "Column",
    category: NodeCategory.layout,
    icon: Icons.table_rows_sharp,
    nodeBuilder: (id, position) => ColumnNode(id: id, position: position),
  ),
  NodeType(
    name: "Row",
    category: NodeCategory.layout,
    icon: Icons.view_column,
    nodeBuilder: (id, position) => RowNode(id: id, position: position),
  ),
  NodeType(
    name: "String",
    category: NodeCategory.data,
    icon: Icons.text_fields,
    nodeBuilder: (id, position) => StringNode(id: id, position: position),
  ),
  NodeType(
    name: "Text",
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
    category: NodeCategory.widget,
    nodeBuilder: (id, position) => ContainerNode(id: id, position: position),
  ),
];

class NodeType {
  final String name;
  final NodeCategory category;
  final IconData? icon;
  final Node Function(String id, Offset position) nodeBuilder;

  const NodeType({
    required this.name,
    this.icon,
    required this.category,
    required this.nodeBuilder,
  });
}
