import 'package:flutter/material.dart';

class WindowTab extends StatelessWidget {
  final bool selected;
  final String name;
  final void Function() onSelect;
  const WindowTab({
    super.key,
    required this.selected,
    required this.name,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: Durations.short2,
        color: selected
            ? theme.colorScheme.surfaceContainer
            : theme.colorScheme.surfaceDim,
        width: 200,
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsetsDirectional.only(start: 8),
        child: Text(
          name,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
