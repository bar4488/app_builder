import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

void main() {
  // field doesnt exist
  // GestureBinding.instance.dragStartBehavior = DragStartBehavior.down;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blueprint Demo – Zoomable',
      theme: ThemeData.dark(useMaterial3: false),
      home: const Scaffold(body: SafeArea(child: BlueprintEditor())),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Basic data
// ────────────────────────────────────────────────────────────────────────────

class Node {
  Node({required this.id, required this.position});
  final String id;
  Offset position; // world‑space (unscaled, untranslated)
  List<Pin> get inputs =>
      List.generate(2, (i) => Pin(nodeId: id, index: i, isInput: true));
  List<Pin> get outputs =>
      List.generate(2, (i) => Pin(nodeId: id, index: i, isInput: false));
}

class Pin {
  Pin({required this.nodeId, required this.index, required this.isInput});
  final String nodeId;
  final int index;
  final bool isInput;
  @override
  bool operator ==(Object other) =>
      other is Pin &&
      nodeId == other.nodeId &&
      index == other.index &&
      isInput == other.isInput;
  @override
  int get hashCode => Object.hash(nodeId, index, isInput);
}

class Connection {
  Connection({required this.from, required this.to});
  final Pin from;
  final Pin to;
}

// ────────────────────────────────────────────────────────────────────────────
//  Editor widget
// ────────────────────────────────────────────────────────────────────────────

class BlueprintEditor extends StatefulWidget {
  const BlueprintEditor({super.key});
  @override
  State<BlueprintEditor> createState() => _BlueprintEditorState();
}

// Constants
const Size nodeSize = Size(160, 100);

class _BlueprintEditorState extends State<BlueprintEditor> {
  final List<Node> _nodes = [];
  final List<Connection> _connections = [];

  // Pan + Zoom
  Offset _canvasOffset = Offset.zero; // screen‑space translation
  double _scale = 1.0;
  bool _isPanning = false;

  // Cable dragging state
  Pin? _dragFrom;
  Offset? _mousePos;

  // ───────────────────────────────────────── Build ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handleScrollZoom,
      child: GestureDetector(
        onSecondaryTapDown: (d) => _addNode(_screenToWorld(d.localPosition)),
        onPanStart: (d) => _startPan(),
        onPanUpdate: (d) => _updatePan(d.delta),
        onPanEnd: (_) => _isPanning = false,
        child: MouseRegion(
          child: Container(
            color: const Color(0xFF242424),
            child: Stack(
              children: [
                // Transform the whole canvas with current pan/zoom
                Transform(
                  alignment: Alignment.topLeft,
                  transform:
                      Matrix4.identity()
                        ..translate(_canvasOffset.dx, _canvasOffset.dy)
                        ..scale(_scale),
                  child: Stack(
                    children: [
                      // Grid
                      Positioned.fill(
                        child: CustomPaint(
                          painter: GridPainter(
                            offset: _canvasOffset,
                            scale: _scale,
                          ),
                        ),
                      ),
                      // Connections (ignore pointer)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: ConnectionPainter(
                              nodes: _nodes,
                              offset: _canvasOffset,
                              scale: _scale,
                              connections: _connections,
                              tempFrom: _dragFrom,
                              tempToPos: _mousePos,
                            ),
                          ),
                        ),
                      ),
                      // Nodes
                      ..._nodes.map(_buildNode),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────── Node widget ──────────────────────────
  Widget _buildNode(Node node) {
    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: Listener(
        onPointerDown:
            (_) => _isPanning = false, // avoid starting pan on node drag
        child: Draggable<Node>(
          data: node,
          feedback: _NodeFrame(size: nodeSize, opacity: 0.7, scale: _scale),
          childWhenDragging: const SizedBox.shrink(),
          onDragEnd:
              (d) => setState(() => node.position = _screenToWorld(d.offset)),
          child: _NodeFrame(
            size: nodeSize,
            scale: _scale,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: node.inputs.map(_buildPin).toList(),
              ),
              const Expanded(
                child: Center(
                  child: Text('General Node', style: TextStyle(fontSize: 14)),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: node.outputs.map(_buildPin).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPin(Pin pin) => GestureDetector(
    onPanDown: (_) => setState(() => _dragFrom = pin),
    onPanUpdate: (details) {
      if (_dragFrom != null) setState(() => _mousePos = details.globalPosition);
    },
    onPanEnd: (_) => _finishCable(pin),
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Icon(
        Icons.circle,
        size: 14,
        color: Colors.orangeAccent,
        opticalSize: _scale,
      ),
    ),
  );

  // ────────────────────────── Pan/Zoom helpers ──────────────────────────
  void _startPan() => _isPanning = true;
  void _updatePan(Offset delta) {
    if (_isPanning && _dragFrom == null) setState(() => _canvasOffset += delta);
  }

  void _handleScrollZoom(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    final mousePos = e.localPosition;
    final worldPos = _screenToWorld(mousePos);
    // Dy < 0  → zoom in
    final zoomFactor = e.scrollDelta.dy < 0 ? 1.1 : 0.9;
    final newScale = (_scale * zoomFactor).clamp(0.25, 4.0);
    setState(() {
      _scale = newScale;
      _canvasOffset = mousePos - worldPos * _scale;
    });
  }

  Offset _screenToWorld(Offset screen) => (screen - _canvasOffset) / _scale;

  // ────────────────────────── Node + Cable logic ──────────────────────────
  void _addNode(Offset worldPos) {
    setState(
      () => _nodes.add(
        Node(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          position: worldPos,
        ),
      ),
    );
  }

  void _finishCable(Pin to) {
    if (_dragFrom != null &&
        _dragFrom != to &&
        _dragFrom!.isInput != to.isInput) {
      final outPin = _dragFrom!.isInput ? to : _dragFrom!;
      final inPin = _dragFrom!.isInput ? _dragFrom! : to;
      setState(() => _connections.add(Connection(from: outPin, to: inPin)));
    }
    setState(() {
      _dragFrom = null;
      _mousePos = null;
    });
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  UI building blocks
// ────────────────────────────────────────────────────────────────────────────

class _NodeFrame extends StatelessWidget {
  const _NodeFrame({
    required this.size,
    this.children = const [],
    this.opacity = 1,
    this.scale = 1,
  });
  final Size size;
  final List<Widget> children;
  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      alignment: Alignment.topLeft,
      child: Opacity(
        opacity: opacity,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: size.width,
            height: size.height,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: children),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────── Painters ──────────────────────────

class GridPainter extends CustomPainter {
  GridPainter({required this.offset, required this.scale});
  final Offset offset;
  final double scale;
  final Paint _paint = Paint()..color = const Color(0xFF2E2E2E);
  @override
  void paint(Canvas canvas, Size size) {
    final step = 40.0 * scale;
    final startX = (-offset.dx % step) - step;
    final startY = (-offset.dy % step) - step;
    for (double x = startX; x < size.width; x += step)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _paint);
    for (double y = startY; y < size.height; y += step)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConnectionPainter extends CustomPainter {
  ConnectionPainter({
    required this.nodes,
    required this.offset,
    required this.scale,
    required this.connections,
    this.tempFrom,
    this.tempToPos,
  });
  final List<Node> nodes;
  final Offset offset;
  final double scale;
  final List<Connection> connections;
  final Pin? tempFrom;
  final Offset? tempToPos;
  final Paint _paint =
      Paint()
        ..color = Colors.orangeAccent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in connections)
      _drawBezier(canvas, _pinScreen(c.from), _pinScreen(c.to));
    if (tempFrom != null && tempToPos != null)
      _drawBezier(canvas, _pinScreen(tempFrom!), _screenToWorld(tempToPos!));
  }

  Offset _screenToWorld(Offset screen) => (screen - offset) / scale;

  Offset _pinScreen(Pin p) {
    final node = nodes.firstWhere((n) => n.id == p.nodeId);
    final base = node.position;
    final localY = nodeSize.height / 3 + p.index * 24;
    final world = Offset(
      base.dx + (p.isInput ? 0 : nodeSize.width) * scale,
      base.dy + localY * scale,
    );
    return world;
  }

  void _drawBezier(Canvas c, Offset a, Offset b) {
    final o = (b.dx - a.dx).abs() * 0.5;
    final cp1 = a + Offset(o, 0);
    final cp2 = b - Offset(o, 0);
    final path =
        Path()
          ..moveTo(a.dx, a.dy)
          ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, b.dx, b.dy);
    c.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
