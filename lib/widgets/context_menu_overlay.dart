import 'package:flutter/material.dart';

enum NodeCategory {
  layout,
  widget,
  data,
}

class ContextMenuOverlay extends StatefulWidget {
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
  State<ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<ContextMenuOverlay> {
  NodeCategory? _hoveredCategory;
  late Map<NodeCategory, List<MenuItemData>> _menuItems;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    _menuItems = {
      NodeCategory.layout: [
        MenuItemData(
            title: 'Column Node', onTap: () => widget.onAddColumnNode()),
        MenuItemData(title: 'Row Node', onTap: () => widget.onAddRowNode()),
      ],
      NodeCategory.widget: [
        MenuItemData(title: 'Text Node', onTap: () => widget.onAddTextNode()),
      ],
      NodeCategory.data: [
        MenuItemData(
            title: 'String Node', onTap: () => widget.onAddStringNode()),
      ],
    };
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
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
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
                                _buildCategoryItem(
                                    NodeCategory.layout, 'Layout'),
                                _buildCategoryItem(
                                    NodeCategory.widget, 'Widgets'),
                                _buildCategoryItem(NodeCategory.data, 'Data'),
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
