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
  final Map<String, T> enumValues;
  final NodeVariable<T> variable;
  final Node node;

  const EnumValueEditor({
    super.key,
    required this.node,
    required this.variable,
    required this.enumValues,
    this.label = "Enum Value",
  });

  @override
  State<EnumValueEditor<T>> createState() => _EnumValueEditorState<T>();
}

class _EnumValueEditorState<T> extends State<EnumValueEditor<T>> {
  T? value;
  @override
  void initState() {
    value = widget.variable.value;
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
                child: DropdownButtonFormField<T>(
                  value: widget.variable.valueOrNull,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: widget.label,
                  ),
                  items: widget.enumValues.entries
                      .map((entry) => DropdownMenuItem<T>(
                            value: entry.value,
                            child: Text(
                              entry.key,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: widget.variable.inputPin != null
                      ? null
                      : (newValue) {
                          if (newValue != null) {
                            widget.variable
                                .setValueNode(ConstValueNode(newValue));
                          } else {
                            widget.variable.setValueNode(null);
                          }
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
                child: TextField(
                  controller: TextEditingController(text: variable.valueOrNull),
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
