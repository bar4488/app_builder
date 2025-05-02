import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:app_builder/models/exceptions.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/variable.dart';
import 'package:app_builder/state/blueprint_state.dart';

abstract class RenderData<T extends Node> {
  RenderData();

  Widget Function() getBuilder(
    BlueprintState state,
    T node,
  );

  Widget build(BlueprintState state, T node) {
    var variables = node.getVariables();

    // if null, throw exception
    for (var e in variables) {
      if (e.getValueNode() == null) {
        throw NodeValueException(
          node.id,
          "Variable ${e.name} is not initialized",
        );
      }
    }
    var renderTargets = node.getRenderTargets();
    for (var e in renderTargets) {
      if (e.targetNodeId == null) {
        throw NodeRenderException(
          node.id,
          "Render target ${e.name} is not initialized",
        );
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

class RenderTarget {
  String name;
  String? targetNodeId;
  RenderTarget({required this.name});

  Widget build(BlueprintState state) {
    var node = state.findNodeById(targetNodeId!)!;
    return node.renderData!.build(state, node);
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
