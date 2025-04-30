import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/widgets/preview_panel.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blueprint Editor'),
        actions: [
          IconButton(
            icon: Icon(
                _leftDrawerOpen ? Icons.chevron_left : Icons.chevron_right),
            onPressed: () => setState(() => _leftDrawerOpen = !_leftDrawerOpen),
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
              child: ChangeNotifierProvider(
                create: (context) => BlueprintEditorState(),
                child: const BlueprintEditorWidget(),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _rightDrawerOpen ? 250 : 0,
            child: _rightDrawerOpen
                ? Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: const Center(
                      child: Text('Right Panel'),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
