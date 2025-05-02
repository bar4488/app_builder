import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/pin.dart';
import 'package:unreal_editor/models/variable.dart';
import 'package:unreal_editor/state/blueprint_state.dart';

abstract class NodeSettigns<T extends Node> {
  Widget buildSettingsWidget(BuildContext context, T node);
}

class EnumValueEditor<T> extends StatefulWidget {
  final String label;
  final List<MapEntry<String, T>> enumValues;
  final NodeVariable<T> variable;
  final List<Widget>? prefixes;
  final Node node;

  EnumValueEditor({
    super.key,
    required this.node,
    required this.variable,
    required this.enumValues,
    this.prefixes,
    this.label = "Enum Value",
  }) {
    assert(prefixes == null || prefixes!.length == enumValues.length);
  }

  @override
  State<EnumValueEditor<T>> createState() => _EnumValueEditorState<T>();
}

class _EnumValueEditorState<T> extends State<EnumValueEditor<T>> {
  int? index;
  @override
  void initState() {
    var value = widget.variable.valueOrNull;
    if (value is T) {
      index = widget.enumValues.map((e) => e.value).toList().indexOf(value);
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
                    labelText: widget.label,
                  ),
                  selectedItemBuilder: (context) => List.generate(
                      widget.enumValues.length,
                      (index) => Row(
                            children: [
                              if (widget.prefixes != null) ...[
                                widget.prefixes![index],
                                const SizedBox(
                                  width: 4,
                                )
                              ],
                              Text(
                                widget.enumValues[index].key,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )).toList(),
                  items: List.generate(
                      widget.enumValues.length,
                      (index) => DropdownMenuItem<int>(
                            value: index,
                            child: ListTile(
                              leading: widget.prefixes != null
                                  ? widget.prefixes![index]
                                  : null,
                              title: Text(
                                widget.enumValues[index].key,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )).toList(),
                  onChanged: widget.variable.inputPin != null
                      ? null
                      : (newIndex) {
                          if (newIndex != null) {
                            widget.variable.setValueNode(ConstValueNode(
                                widget.enumValues[newIndex].value));
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
              if (widget.variable.canBindInputPin)
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
              if (variable.canBindInputPin)
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
        var inputPin = InputValuePin<T>(
          nodeId: node.id,
          label: variable.name,
          onValueChanged: (value) {
            variable.setValueNode(value);
          },
        );
        node.addInputPin(inputPin);
        variable.bindInputPin(inputPin);
      },
    );
  }
}
