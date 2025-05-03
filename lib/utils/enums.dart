import 'package:flutter/material.dart';
import 'package:runtime_type/runtime_type.dart';

abstract final class Enums {
  static const EnumType<Color> colors = EnumType("Color", [
    MapEntry("red", Colors.red),
    MapEntry("pink", Colors.pink),
    MapEntry("purple", Colors.purple),
    MapEntry("deepPurple", Colors.deepPurple),
    MapEntry("indigo", Colors.indigo),
    MapEntry("blue", Colors.blue),
    MapEntry("lightBlue", Colors.lightBlue),
    MapEntry("cyan", Colors.cyan),
    MapEntry("teal", Colors.teal),
    MapEntry("green", Colors.green),
    MapEntry("lightGreen", Colors.lightGreen),
    MapEntry("lime", Colors.lime),
    MapEntry("yellow", Colors.yellow),
    MapEntry("amber", Colors.amber),
    MapEntry("orange", Colors.orange),
    MapEntry("deepOrange", Colors.deepOrange),
    MapEntry("brown", Colors.brown),
    MapEntry("blueGrey", Colors.blueGrey),
  ]);

  static const EnumType<Alignment> alignment = EnumType(
    "Alignment",
    [
      MapEntry("Top Left", Alignment.topLeft),
      MapEntry("Top Center", Alignment.topCenter),
      MapEntry("Top Right", Alignment.topRight),
      MapEntry("Center Left", Alignment.centerLeft),
      MapEntry("Center", Alignment.center),
      MapEntry("Center Right", Alignment.centerRight),
      MapEntry("Bottom Left", Alignment.bottomLeft),
      MapEntry("Bottom Center", Alignment.bottomCenter),
      MapEntry("Bottom Right", Alignment.bottomRight),
    ],
  );

  static const EnumType<EnumType> types = EnumType(
    "Type",
    [
      MapEntry("Color", colors),
      MapEntry("Alignment", alignment),
    ],
  );

  static List<MapEntry<String, T?>> getNullable<T>(
          List<MapEntry<String, T>> list) =>
      [const MapEntry("None", null), ...list];
}

class EnumType<T> {
  final String name;
  RuntimeType get type => RuntimeType<T>();
  final List<MapEntry<String, T>> enumValues;

  List<MapEntry<String, T?>> get nullableEnumValues =>
      Enums.getNullable(enumValues);

  const EnumType(this.name, this.enumValues);
}
