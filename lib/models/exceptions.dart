class NodeValueException implements Exception {
  final String nodeId;
  final String errorMessage;
  NodeValueException(this.nodeId, this.errorMessage);

  @override
  String toString() {
    return "NodeValueException: id: $nodeId, error: $errorMessage";
  }
}

class NodeRenderException implements Exception {
  final String nodeId;
  final String errorMessage;
  NodeRenderException(this.nodeId, this.errorMessage);

  @override
  String toString() {
    return "NodeRenderException: id: $nodeId, error: $errorMessage";
  }
}
