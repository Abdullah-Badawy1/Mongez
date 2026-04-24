import 'package:flutter/material.dart';
import 'package:mongez/core/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width; // اختياري
  final double height;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final bool hasBorder; // لو true هنعمل بوردر
  final Color borderColor; // لون البوردر

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width, // لو null => full width
    this.height = 50,
    this.backgroundColor = AppColors.primary,
    this.textColor = Colors.white,
    this.borderRadius = 16,
    this.fontSize = 18,
    this.fontWeight = FontWeight.bold,
    this.hasBorder = false, // بشكل افتراضي مفيش بوردر
    this.borderColor = Colors.white, // اللون الافتراضي للبوردر
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: hasBorder
                ? BorderSide(color: borderColor, width: 2)
                : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
