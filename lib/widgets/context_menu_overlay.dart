import 'package:flutter/material.dart';

class ContextMenuOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onAddNode;

  const ContextMenuOverlay({
    super.key,
    required this.onDismiss,
    required this.onAddNode,
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
              title: const Text('Add Node'),
              onTap: onAddNode,
            ),
          ],
        ),
      ),
    );
  }
}
