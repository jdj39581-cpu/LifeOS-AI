import 'package:flutter/material.dart';

class LifeOSUI {
  static const bg = Color(0xFF0F172A);
  static const cardColor = Color(0xFF1E293B);

  static AppBar appBar(String title) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      backgroundColor: bg,
      elevation: 0,
    );
  }

  static Widget card({required Widget child}) {
    return Card(
      color: cardColor,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: child,
    );
  }

  static Widget fab(VoidCallback onPressed) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF06B6D4),
      onPressed: onPressed,
      child: const Icon(Icons.add),
    );
  }
}
