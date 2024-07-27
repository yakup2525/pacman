import 'package:flutter/material.dart';

class YellowGhost extends StatelessWidget {
  const YellowGhost({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Image.asset('assets/images/yellow_ghost.png'),
    );
  }
}
