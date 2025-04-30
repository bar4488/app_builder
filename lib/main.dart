import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/pin.dart';
import 'package:unreal_editor/painters/connection_painter.dart';
import 'package:unreal_editor/painters/grid_painter.dart';
import 'package:unreal_editor/state/blueprint_editor_state.dart';
import 'package:unreal_editor/widgets/editor_window.dart';
import 'package:unreal_editor/widgets/node_widget.dart';

// --- Main Application Widget ---

void main() {
  runApp(const BlueprintEditorApp());
}

class BlueprintEditorApp extends StatelessWidget {
  const BlueprintEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Blueprint Editor Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
      ),
      home: const EditorWindow(),
      debugShowCheckedModeBanner: false,
    );
  }
}
