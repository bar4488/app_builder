import 'package:flutter/material.dart';

class ContextMenuOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onAddColumnNode;
  final VoidCallback onAddRowNode;
  final VoidCallback onAddTextNode;
  final VoidCallback onAddStringNode;

  const ContextMenuOverlay({
    super.key,
    required this.onDismiss,
    required this.onAddColumnNode,
    required this.onAddRowNode,
    required this.onAddTextNode,
    required this.onAddStringNode,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(4),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add Column Node'),
              onTap: onAddColumnNode,
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add Row Node'),
              onTap: onAddRowNode,
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add Text Node'),
              onTap: onAddTextNode,
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add String Node'),
              onTap: onAddStringNode,
            ),
          ],
        ),
      ),
    );
  }
}
