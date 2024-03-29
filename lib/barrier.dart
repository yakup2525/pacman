import 'package:flutter/material.dart';

//Bariyer Widget pixel indexed
class Barrier extends StatelessWidget {
  final Color barrierColor;

  const Barrier({super.key, required this.barrierColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Image.asset('lib/images/barrier.png'),
    );
  }
}
