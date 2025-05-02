import 'package:flutter/material.dart';
import 'package:unreal_editor/models/nodes.dart';
import 'package:unreal_editor/utils/string_extensions.dart';

class ContextMenuOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final void Function(NodeType nodeType) onAddNode;

  const ContextMenuOverlay({
    super.key,
    required this.onDismiss,
    required this.onAddNode,
  });

  @override
  State<ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<ContextMenuOverlay> {
  NodeCategory? _hoveredCategory;
  late Map<NodeCategory, List<MenuItemData>> _menuItems;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  var focusNode = FocusNode();

  @override
  void initState() {
    focusNode.requestFocus();
    _menuItems = {};
    for (final nodeType in nodeTypes) {
      if (nodeType.category == NodeCategory.internal) continue;
      _menuItems[nodeType.category] ??= [];
      _menuItems[nodeType.category]!.add(MenuItemData(
        title: nodeType.name,
        onTap: () {
          widget.onAddNode(nodeType);
          widget.onDismiss();
        },
      ));
    }
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MenuItemData> get _searchResults {
    if (_searchQuery.isEmpty) return [];
    final query = _searchQuery.toLowerCase();
    return _menuItems.values
        .expand((items) => items)
        .where((item) => item.title.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 300,
          minWidth: 200,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main menu with search
            SizedBox(
              width: 150,
              child: Column(
                children: [
                  // Search field
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      autofocus: true,
                      controller: _searchController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        if (_searchResults.isNotEmpty) {
                          _searchResults.first.onTap!();
                          widget.onDismiss();
                        }
                      },
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                  // Categories or search results
                  Expanded(
                    child: SingleChildScrollView(
                      child: _searchQuery.isNotEmpty
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _searchResults
                                  .map((item) => _buildMenuItem(item))
                                  .toList(),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final category in _menuItems.keys)
                                  _buildCategoryItem(
                                    category,
                                    category.name.capitalize(),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            // Submenu (only show when not searching)
            if (_hoveredCategory != null && _searchQuery.isEmpty)
              SizedBox(
                width: 200,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _menuItems[_hoveredCategory]!
                          .map((item) => _buildMenuItem(item))
                          .toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(NodeCategory category, String title) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCategory = category),
      child: ListTile(
        dense: true,
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, size: 16),
      ),
    );
  }

  Widget _buildMenuItem(MenuItemData item) {
    return ListTile(
      dense: true,
      title: Text(item.title),
      onTap: item.onTap,
    );
  }
}

class MenuItemData {
  final String title;
  final VoidCallback? onTap;

  MenuItemData({required this.title, this.onTap});
}
