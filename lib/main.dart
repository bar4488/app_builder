import 'package:flutter/material.dart';
import 'package:unreal_editor/widgets/editor_window.dart';

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
