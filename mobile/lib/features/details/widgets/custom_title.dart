import 'package:flutter/material.dart';
import 'package:mongez/core/app_colors.dart';

class CustomTitle extends StatelessWidget {
  final String title;

  const CustomTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gray9,
              ),
            ),
            Divider(color: AppColors.gray2, thickness: 2),
          ],
        ),
      ),
    );
  }
}
