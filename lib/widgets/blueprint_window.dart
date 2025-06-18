import 'dart:convert';
import 'dart:io';
import 'package:app_builder/state/blueprint_state.dart';
import 'package:app_builder/state/editor_window_state.dart';
import 'package:app_builder/widgets/blueprint_editor_widget.dart';
import 'package:app_builder/widgets/blueprint_variables_panel.dart';
import 'package:app_builder/widgets/preview_panel.dart';
import 'package:app_builder/widgets/resizable_panel.dart';
import 'package:app_builder/widgets/settings_panel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlueprintWindow extends StatelessWidget {
  const BlueprintWindow({super.key});

  Future<void> _exportToJson(BuildContext context) async {
    try {
      // Get the blueprint state directly
      final blueprintState = context.read<BlueprintState>();
      final blueprintData = blueprintState.toJson();

      // Convert to JSON string with pretty formatting
      final jsonString =
          const JsonEncoder.withIndent('  ').convert(blueprintData);

      // Let user choose where to save the file
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Blueprint to JSON',
        fileName: 'blueprint.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        // Write the JSON to the selected file
        final file = File(outputFile);
        await file.writeAsString(jsonString);

        // Show success message with open button
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Blueprint exported successfully to: $outputFile'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () async {
                  try {
                    if (Platform.isWindows) {
                      await Process.start('explorer.exe', [outputFile]);
                      return;
                    }
                  } catch (e) {
                    // error
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open file: $outputFile'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting blueprint: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importFromJson(BuildContext context) async {
    try {
      final blueprintState = context.read<BlueprintState>();

      FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import Blueprint from JSON',
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['json'],
      );

      PlatformFile? inputFile = pickerResult?.files.firstOrNull;
      if (inputFile != null) {
        File file = File(inputFile.path!);

        JsonDecoder decoder = const JsonDecoder();
        var json = decoder.convert(await file.readAsString());

        blueprintState.loadFromJson(json);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Blueprint imported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing blueprint: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var windowState = context.watch<EditorWindowState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blueprint Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Import from JSON',
            onPressed: () => _importFromJson(context),
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Export to JSON',
            onPressed: () => _exportToJson(context),
          ),
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
