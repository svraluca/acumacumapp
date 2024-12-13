import 'package:flutter/material.dart';
import 'package:acumacum/ui/auth.dart';

class Provider extends InheritedWidget {
  final Authentication auth;
  final db;

  const Provider({
    super.key,
    required super.child,
    required this.auth,
    this.db,
  });

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return true;
  }

  static Provider of(BuildContext context) => (context.dependOnInheritedWidgetOfExactType<Provider>() as Provider);
}
