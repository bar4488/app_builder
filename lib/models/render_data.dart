import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:unreal_editor/models/exceptions.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/variable.dart';
import 'package:unreal_editor/state/blueprint_state.dart';

abstract class RenderData<T extends Node> {
  RenderData();

  Widget Function() getBuilder(
    BlueprintState state,
    T node,
  );

  Iterable<NodeVariable> getVariables(T node);

  Widget build(BlueprintState state, T node) {
    var variables = getVariables(node);

    // if null, throw exception
    for (var e in variables) {
      if (e.getValueNode() == null) {
        throw NodeValueException(
            node.id, "Variable ${e.name} is not initialized");
      }
    }
    // get all change notifiers
    var listeners = variables
        .map((e) => e.getValueNode()!)
        .whereType<ChangeValueNode>()
        .toList();

    var builder = getBuilder(state, node);
    if (listeners.isEmpty) {
      if (node.highlightColor != null) {
        return Stack(
          children: [
            builder(),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: node.highlightColor!,
                  ),
                ),
              ),
            ),
          ],
        );
      }
      return builder();
    }

    return ChangeValueWidget(
      listeners: listeners,
      builder: (context) {
        if (node.highlightColor != null) {
          return Stack(
            children: [
              builder(),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: node.highlightColor!,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return builder();
      },
    );
  }
}

class ChangeValueWidget extends StatefulWidget {
  final List<ChangeNotifier> listeners;
  final Widget Function(BuildContext) _builder;
  const ChangeValueWidget({
    super.key,
    this.listeners = const [],
    required Widget Function(BuildContext) builder,
  }) : _builder = builder;

  @override
  State<ChangeValueWidget> createState() => _ChangeValueWidgetState();
}

class _ChangeValueWidgetState extends State<ChangeValueWidget> {
  void onChange() {
    setState(() {});
  }

  @override
  void initState() {
    for (var listener in widget.listeners) {
      listener.addListener(onChange);
    }
    super.initState();
  }

  @override
  void dispose() {
    for (var listener in widget.listeners) {
      listener.removeListener(onChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget._builder(context);
  }
}
