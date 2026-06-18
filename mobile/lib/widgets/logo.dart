import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mongez/core/app_colors.dart';

/// Mongez brand mark. Renders the SVG logo when available, falls back to
/// a plain wordmark if the asset bundle can't load it (older builds /
/// missing asset). `compact` shrinks the layout for use inside an
/// AppBar.
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
        SvgPicture.asset(
          'assets/images/logo-mark.svg',
          width: markSize,
          height: markSize,
          placeholderBuilder: (_) => Container(
            width: markSize,
            height: markSize,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(markSize * 0.25),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.build_rounded,
                color: Colors.white, size: markSize * 0.55),
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
