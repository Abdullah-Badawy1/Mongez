import 'package:flutter/material.dart';

class AddButton extends StatelessWidget {
  final String title;
  final void Function()? onPressed;
  const AddButton({super.key, required this.title, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        // لون الإطار (Border)
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
        // انحناء الحواف
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // المساحة الداخلية للزرار
        padding: const EdgeInsets.symmetric(vertical: 18),
        // اللون عند الضغط
        foregroundColor: Colors.black,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, color: Colors.black87), // علامة الـ +
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2E2E), // لون غامق قريب من اللي في الصورة
            ),
          ),
        ],
      ),
    );
  }
}
