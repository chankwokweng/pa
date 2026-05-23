import 'package:flutter/material.dart';
import '../utils/icon_map.dart';

class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const AppIcon(this.name, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(iconFor(name), size: size, color: color);
  }
}
