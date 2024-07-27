import 'package:flutter/material.dart';

class BlueGhost extends StatelessWidget {
  const BlueGhost({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Image.asset('assets/images/blue_ghost.png'),
    );
  }
}
