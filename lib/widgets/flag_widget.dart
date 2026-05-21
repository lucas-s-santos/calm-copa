import 'package:flutter/material.dart';

class FlagWidget extends StatelessWidget {
  final String flag;
  final double size;

  const FlagWidget({super.key, required this.flag, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Text(flag, style: TextStyle(fontSize: size));
  }
}
