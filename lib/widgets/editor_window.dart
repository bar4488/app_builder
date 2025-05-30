import 'package:app_builder/state/preview_state.dart';
import 'package:app_builder/widgets/blueprint_window.dart';
import 'package:app_builder/widgets/window_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_builder/state/blueprint_state.dart';
import 'package:app_builder/state/editor_window_state.dart';
import 'package:app_builder/widgets/preview_panel.dart';
import 'package:app_builder/widgets/settings_panel.dart';
import '../state/blueprint_editor_state.dart';
import 'blueprint_editor_widget.dart';

class EditorWindow extends StatelessWidget {
  const EditorWindow({super.key});

  @override
  Widget build(BuildContext context) {
    var windowState = context.watch<EditorWindowState>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => BlueprintState(),
        ),
        ChangeNotifierProvider(
          create: (context) => PreviewState(
            context.read<BlueprintState>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              BlueprintEditorState(context.read<BlueprintState>()),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: SizedBox(
                width: double.infinity,
                height: 38,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      WindowTab(
                        name: "Blueprint",
                        selected: windowState.selectedTab == 0,
                        onSelect: () {
                          windowState.selectTab(0);
                        },
                      ),
                      WindowTab(
                        name: "State",
                        selected: windowState.selectedTab == 1,
                        onSelect: () {
                          windowState.selectTab(1);
                        },
                      ),
                      WindowTab(
                        name: "Animator",
                        selected: windowState.selectedTab == 2,
                        onSelect: () {
                          windowState.selectTab(2);
                        },
                      ),
                    ],
                  ),
                ),
              )),
          Expanded(
            child: IndexedStack(
              index: windowState.selectedTab,
              children: const [
                BlueprintWindow(),
                Placeholder(),
                Placeholder(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
