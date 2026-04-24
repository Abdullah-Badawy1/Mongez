import 'package:flutter/material.dart';
import 'package:mongez/core/app_colors.dart';

class CustomSupTitle extends StatelessWidget {
  final String supTitle;

  const CustomSupTitle({super.key, required this.supTitle});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              supTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray9,
              ),
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}
