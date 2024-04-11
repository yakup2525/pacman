import 'package:flutter/material.dart';

class Path extends StatelessWidget {
  final Color innerColor;
  final Color outerColor;
  final Widget child;

  const Path(
      {super.key,
      required this.innerColor,
      required this.outerColor,
      required this.child});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: ClipRRect(
        //  borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(12),
          color: outerColor,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: innerColor,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
