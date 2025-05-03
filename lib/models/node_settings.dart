import 'package:app_builder/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/pin.dart';
import 'package:app_builder/models/variable.dart';
import 'package:app_builder/state/blueprint_state.dart';

abstract class NodeSettigns<T extends Node> {
  Widget buildSettingsWidget(BuildContext context, T node);
}

class EnumValueEditor<T> extends StatefulWidget {
  final NodeVariable<T> variable;
  final Node node;
  final FocusNode? focus;
  final EnumType enumType;

  const EnumValueEditor({
    super.key,
    required this.node,
    required this.variable,
    required this.enumType,
    this.focus,
  });

  @override
  State<EnumValueEditor<T>> createState() => _EnumValueEditorState<T>();
}

class _EnumValueEditorState<T> extends State<EnumValueEditor<T>> {
  int? index;
  late List<MapEntry<String, T>> values;
  @override
  void initState() {
    var value = widget.variable.valueOrNull;
    values = widget.enumType.enumValues
        .map((e) => MapEntry(e.key, e.value as T))
        .toList();
    if (value is T) {
      if (widget.variable.type.isNullable) {
        values.insert(0, MapEntry("None", null as T));
      }
      index = values.indexWhere(
        (element) => element.value == value,
      );
      if (index == -1) {
        index = null;
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: widget.variable,
        builder: (context, child) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: index,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: widget.variable.name,
                  ),
                  selectedItemBuilder: (context) =>
                      List.generate(values.length, (index) {
                    var prefix =
                        widget.enumType.prefixBuilder(values[index].value);
                    return Row(
                      children: [
                        if (prefix != null) ...[
                          prefix,
                          const SizedBox(
                            width: 4,
                          )
                        ],
                        Text(
                          values[index].key,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  }).toList(),
                  items: List.generate(values.length, (index) {
                    var prefix =
                        widget.enumType.prefixBuilder(values[index].value);
                    return DropdownMenuItem<int>(
                      value: index,
                      child: ListTile(
                        leading: prefix,
                        title: Text(
                          values[index].key,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: widget.variable.inputPin != null
                      ? null
                      : (newIndex) {
                          if (newIndex == index) {
                            return;
                          }
                          if (newIndex != null) {
                            widget.variable.setValueNode(
                                ConstValueNode(values[newIndex].value));
                          } else {
                            widget.variable.setValueNode(null);
                          }
                          setState(() {
                            index = newIndex;
                          });
                          context.read<BlueprintState>().notifyListeners();
                        },
                ),
              ),
              if (widget.variable.canBindInput)
                BindButton<T>(node: widget.node, variable: widget.variable)
            ],
          );
        });
  }
}

class StringValueEditor extends StatelessWidget {
  final Node node;
  final NodeVariable<String> variable;
  const StringValueEditor(
      {super.key, required this.node, required this.variable});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: variable,
        builder: (context, child) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: variable.valueOrNull,
                  enabled: variable.inputPin == null,
                  onChanged: (newValue) {
                    variable.setValueNode(ConstValueNode(newValue));
                    context.read<BlueprintState>().notifyListeners();
                  },
                  decoration: InputDecoration(labelText: variable.name),
                ),
              ),
              if (variable.canBindInput)
                BindButton<String>(node: node, variable: variable)
            ],
          );
        });
  }
}

class BindButton<T> extends StatelessWidget {
  final Node node;
  final NodeVariable<T> variable;

  const BindButton({super.key, required this.node, required this.variable});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<BlueprintState>();
    return IconButton(
      icon: Icon(variable.inputPin == null ? Icons.link : Icons.link_off),
      onPressed: () {
        if (variable.inputPin != null) {
          state.removeNodeInputPin(node, variable.inputPin!);
          variable.bindInputPin(null);
          return;
        }
        node.bindInputVariable(variable);
      },
    );
  }
}
