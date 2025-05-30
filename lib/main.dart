import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_builder/state/editor_window_state.dart';
import 'package:app_builder/widgets/editor_window.dart';

void main() {
  runApp(const BlueprintEditorApp());
}

class BlueprintEditorApp extends StatelessWidget {
  const BlueprintEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    bool debug = true;
    var height = 800.0;
    Widget widget = const EditorWindow();
    if (debug) {
      widget = FittedBox(
        child: SizedBox(
          height: height,
          width: MediaQuery.of(context).size.width /
              MediaQuery.of(context).size.height *
              height,
          child: widget,
        ),
      );
    }
    return MaterialApp(
      title: 'Flutter Blueprint Editor Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => EditorWindowState(),
          ),
        ],
        child: widget,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
