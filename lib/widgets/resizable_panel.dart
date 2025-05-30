// a panel containing 2 widgets, displays them in a column.
// between the widgets, has a divider that can be dragged to resize the widgets

import 'package:flutter/material.dart';

class ResizablePanel extends StatefulWidget {
  final Widget topWidget;
  final Widget bottomWidget;
  final double initialTopHeight;
  final double minTopHeight;
  final double minBottomHeight;

  const ResizablePanel({
    Key? key,
    required this.topWidget,
    required this.bottomWidget,
    this.initialTopHeight = 200.0,
    this.minTopHeight = 50.0,
    this.minBottomHeight = 50.0,
  }) : super(key: key);

  @override
  _ResizablePanelState createState() => _ResizablePanelState();
}

class _ResizablePanelState extends State<ResizablePanel> {
  late double _topHeight;

  @override
  void initState() {
    super.initState();
    _topHeight = widget.initialTopHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: _topHeight,
          child: widget.topWidget,
        ),
        MouseRegion(
          cursor: SystemMouseCursors.move,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _topHeight += details.delta.dy;

                // Get the total available height
                final RenderBox box = context.findRenderObject() as RenderBox;
                final totalHeight = box.size.height;

                // Enforce minimum heights
                if (_topHeight < widget.minTopHeight) {
                  _topHeight = widget.minTopHeight;
                }

                if (totalHeight - _topHeight < widget.minBottomHeight) {
                  _topHeight = totalHeight - widget.minBottomHeight;
                }
              });
            },
            child: Container(
              height: 10.0,
              decoration: BoxDecoration(
                // color: Colors.grey.shade300,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade800, width: 1.0),
                  bottom: BorderSide(color: Colors.grey.shade800, width: 1.0),
                ),
              ),
              child: Center(
                child: Container(
                  width: 40.0,
                  height: 5.0,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade500,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: widget.bottomWidget,
        ),
      ],
    );
  }
}
