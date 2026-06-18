import 'package:flutter/material.dart';
import 'package:mongez/core/app_colors.dart';

/// Mongez brand mark. Renders the user-supplied logo image with a
/// bilingual wordmark beside it. `compact` shrinks the layout for use
/// inside an AppBar.
class Logo extends StatelessWidget {
  final bool compact;
  const Logo({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 36.0 : 88.0;
    final titleSize = compact ? 22.0 : 42.0;
    final subtitleSize = compact ? 12.0 : 18.0;
    final gap = compact ? 8.0 : 14.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(markSize * 0.22),
          child: Image.asset(
            'assets/images/logo.jpg',
            width: markSize,
            height: markSize,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: gap),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mongez',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            SizedBox(height: compact ? 1 : 4),
            Text(
              'منجز',
              style: TextStyle(
                fontSize: subtitleSize,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
