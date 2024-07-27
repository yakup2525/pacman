import 'package:flutter/material.dart';

//Player(pacman)
class MyPlayer extends StatelessWidget {
  const MyPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Image.asset(
        'assets/images/pacman.png',
        // width: MediaQuery.of(context).size.width,
        // fit: BoxFit.cover,
      ),
    );
  }
}
