import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/state/blueprint_state.dart';
import 'package:unreal_editor/widgets/preview_panel.dart';
import 'package:unreal_editor/widgets/settings_panel.dart';
import '../state/blueprint_editor_state.dart';
import 'blueprint_editor_widget.dart';

class EditorWindow extends StatefulWidget {
  const EditorWindow({super.key});

  @override
  State<EditorWindow> createState() => _EditorWindowState();
}

class _EditorWindowState extends State<EditorWindow> {
  bool _leftDrawerOpen = true;
  bool _rightDrawerOpen = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => BlueprintState(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              BlueprintEditorState(context.read<BlueprintState>()),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Blueprint Editor'),
          actions: [
            IconButton(
              icon: Icon(
                  _leftDrawerOpen ? Icons.chevron_left : Icons.chevron_right),
              onPressed: () =>
                  setState(() => _leftDrawerOpen = !_leftDrawerOpen),
            ),
            IconButton(
              icon: Icon(
                  _rightDrawerOpen ? Icons.chevron_right : Icons.chevron_left),
              onPressed: () =>
                  setState(() => _rightDrawerOpen = !_rightDrawerOpen),
            ),
          ],
        ),
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _leftDrawerOpen ? 300 : 0,
              child: UnconstrainedBox(
                clipBehavior: Clip.antiAlias,
                constrainedAxis: Axis.vertical,
                alignment: Alignment.topLeft,
                child: Container(
                  alignment: Alignment.centerLeft,
                  width: 300,
                  color: Theme.of(context).colorScheme.surface,
                  child: PreviewPanel(),
                ),
              ),
            ),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Color.lerp(
                      Theme.of(context).primaryColor, Colors.white, 0.05),
                ),
                child: const BlueprintEditorWidget(),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _rightDrawerOpen ? 300 : 0,
              child: UnconstrainedBox(
                clipBehavior: Clip.antiAlias,
                constrainedAxis: Axis.vertical,
                alignment: Alignment.topLeft,
                child: Container(
                  alignment: Alignment.centerLeft,
                  width: 300,
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SettingsPanel(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
