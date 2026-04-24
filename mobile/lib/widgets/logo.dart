import 'package:flutter/material.dart';
import 'package:mongez/core/app_colors.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Mongez',
      style: TextStyle(
        fontSize: 70,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}
