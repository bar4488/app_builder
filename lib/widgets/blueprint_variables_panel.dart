import 'package:app_builder/models/variable.dart';
import 'package:app_builder/state/blueprint_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum VariableType { integer, double, string, boolean }

class BlueprintVariable with ChangeNotifier {
  String name;
  VariableType _type;
  VariableType get type => _type;
  late ChangeValueNode value;

  BlueprintVariable({required this.name, required VariableType type})
      : _type = type {
    value = switch (type) {
      VariableType.integer => ChangeValueNode<int>(0),
      VariableType.double => ChangeValueNode<double>(0.0),
      VariableType.string => ChangeValueNode<String>(""),
      VariableType.boolean => ChangeValueNode<bool>(false),
    };
  }

  void setValue(dynamic newValue) {
    //check that value is of a correct type
    value.value = newValue;
  }

  void setType(VariableType newType) {
    _type = newType;
    value = switch (type) {
      VariableType.integer => ChangeValueNode<int>(0),
      VariableType.double => ChangeValueNode<double>(0.0),
      VariableType.string => ChangeValueNode<String>(""),
      VariableType.boolean => ChangeValueNode<bool>(false),
    };
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'value': value.value,
    };
  }
}

class BlueprintVariablesPanel extends StatelessWidget {
  const BlueprintVariablesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BlueprintState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: const Text(
            'Variables',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: IconButton(
            onPressed: () {
              state.addVariable(BlueprintVariable(
                name: 'New Variable',
                type: VariableType.integer,
              ));
            },
            padding: const EdgeInsets.all(0),
            icon: const Icon(Icons.add),
          ),
        ),
        const Divider(color: Colors.grey),
        const SizedBox(height: 8),
        ...state.variables.asMap().entries.map((entry) {
          final index = entry.key;
          final variable = entry.value;
          return _buildVariableRow(index, variable, state);
        }),
      ],
    );
  }

  Widget _buildVariableRow(
      int index, BlueprintVariable variable, BlueprintState state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          _buildTypeWidget(variable, state),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: TextFormField(
              initialValue: variable.name,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                state.setVariableName(variable, value);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.settings,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeWidget(BlueprintVariable variable, BlueprintState state) {
    // Define constant colors for each variable type
    const Map<VariableType, Color> typeColors = {
      VariableType.integer: Color(0xFF4CAF50), // Green
      VariableType.double: Color(0xFF2196F3), // Blue
      VariableType.string: Color(0xFFFFC107), // Amber
      VariableType.boolean: Color(0xFFE91E63), // Pink
    };

    // Get display names for the overlay
    String getDisplayName(VariableType type) {
      switch (type) {
        case VariableType.integer:
          return 'Integer';
        case VariableType.double:
          return 'Double';
        case VariableType.string:
          return 'String';
        case VariableType.boolean:
          return 'Boolean';
      }
    }

    return Builder(builder: (context) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            // Show overlay for type selection
            final RenderBox button = context.findRenderObject() as RenderBox;
            final Offset position = button.localToGlobal(Offset.zero);

            showMenu<VariableType>(
              context: context,
              position: RelativeRect.fromLTRB(
                position.dx,
                position.dy + button.size.height,
                position.dx + button.size.width,
                position.dy,
              ),
              color: const Color(0xFF2D2D2D),
              items: VariableType.values.map((VariableType type) {
                return PopupMenuItem<VariableType>(
                  value: type,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: typeColors[type],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        getDisplayName(type),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ).then((VariableType? newType) {
              if (newType != null) {
                state.setVariableType(variable, newType);
              }
            });
          },
          child: Container(
            decoration: const BoxDecoration(),
            padding: const EdgeInsets.all(4),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: typeColors[variable.type],
                borderRadius: BorderRadius.circular(4),
              ),
              width: 16,
              height: 8,
            ),
          ),
        ),
      );
    });
  }
}
