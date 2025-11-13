import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ignore: camel_case_types
class custom360RotationImage extends StatefulWidget {
   const custom360RotationImage({super.key});

  @override
   State<custom360RotationImage> createState() => custom360RotationImageState();
}

// ignore: camel_case_types
class custom360RotationImageState extends State<custom360RotationImage>
    with SingleTickerProviderStateMixin {
  late AnimationController rotationController;

  @override
  void initState() {
    rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    rotationController.repeat();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rotationController,
      builder: (_, child) {
        return Transform.rotate(
          angle: rotationController.value * 2 * math.pi,
          child: child,
        );
      },
      child: Image.asset(
        "assets/Spinner.png",
      ),
    );
  }
}