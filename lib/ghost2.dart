import 'package:flutter/material.dart';

class RedGhost extends StatelessWidget {
  const RedGhost({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Image.asset('assets/images/red_ghost.png'),
    );
  }
}
