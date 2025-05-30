import 'package:app_builder/state/editor_window_state.dart';
import 'package:app_builder/widgets/blueprint_editor_widget.dart';
import 'package:app_builder/widgets/blueprint_variables_panel.dart';
import 'package:app_builder/widgets/preview_panel.dart';
import 'package:app_builder/widgets/resizable_panel.dart';
import 'package:app_builder/widgets/settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlueprintWindow extends StatelessWidget {
  const BlueprintWindow({super.key});

  @override
  Widget build(BuildContext context) {
    var windowState = context.watch<EditorWindowState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blueprint Editor'),
        actions: [
          IconButton(
              icon: Icon(windowState.leftDrawerOpen
                  ? Icons.chevron_left
                  : Icons.chevron_right),
              onPressed: windowState.toggleLeftDrawer),
          IconButton(
            icon: Icon(windowState.rightDrawerOpen
                ? Icons.chevron_right
                : Icons.chevron_left),
            onPressed: windowState.toggleRightDrawer,
          ),
        ],
      ),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: windowState.leftDrawerOpen ? 300 : 0,
            child: UnconstrainedBox(
              clipBehavior: Clip.antiAlias,
              constrainedAxis: Axis.vertical,
              alignment: Alignment.topLeft,
              child: Container(
                alignment: Alignment.centerLeft,
                width: 300,
                color: Theme.of(context).colorScheme.surface,
                child: const ResizablePanel(
                  topWidget: PreviewPanel(),
                  bottomWidget: BlueprintVariablesPanel(),
                ),
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
            width: windowState.rightDrawerOpen ? 300 : 0,
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
                  child: FocusTraversalGroup(
                    child: SettingsPanel(
                      key: windowState.settingsPanelKey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
