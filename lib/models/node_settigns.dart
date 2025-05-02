import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/render_data.dart';
import 'package:unreal_editor/models/pin.dart';
import 'package:unreal_editor/state/blueprint_editor_state.dart';
import 'package:unreal_editor/state/blueprint_state.dart';

abstract class NodeSettigns<T extends Node> {
  Widget buildSettingsWidget(BuildContext context, T node);
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

class RowNodeSettigns extends NodeSettigns<RowNode> {
  @override
  Widget buildSettingsWidget(BuildContext context, RowNode node) {
    return ListView(
      children: [
        EnumValueEditor<MainAxisAlignment>(
          node: node,
          variable: node.mainAxisAlignment,
          enumValues: MainAxisAlignment.values.asMap().map(
                (key, value) => MapEntry(
                  value.toString(),
                  value,
                ),
              ),
        ),
        EnumValueEditor<CrossAxisAlignment>(
          node: node,
          variable: node.crossAxisAlignment,
          enumValues: CrossAxisAlignment.values.asMap().map(
                (key, value) => MapEntry(
                  value.toString(),
                  value,
                ),
              ),
        ),
      ],
    );
  }
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
              BindButton<T>(node: widget.node, variable: widget.variable)
            ],
          );
        });
  }
}

class StringValueEditor extends StatelessWidget {
  final OutputValuePin<String> pin;
  final String label;
  const StringValueEditor(
      {super.key, required this.pin, this.label = "String Value"});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: pin.value?.value),
      onChanged: (newValue) {
        pin.update(ConstValueNode(newValue));
        context.read<BlueprintState>().notifyListeners();
      },
      decoration: InputDecoration(labelText: label),
    );
  }
}

class BindButton<T> extends StatelessWidget {
  final Node node;
  final NodeVariable<T> variable;

  const BindButton({super.key, required this.node, required this.variable});

  @override
  Widget build(BuildContext context) {
    context.watch<BlueprintState>();
    return IconButton(
      icon: Icon(variable.inputPin == null ? Icons.link : Icons.link_off),
      onPressed: () {
        if (variable.inputPin != null) {
          node.removeInputPin(variable.inputPin!);
          variable.bindInputPin(null);
          return;
        }
        var state = context.read<BlueprintState>();
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
