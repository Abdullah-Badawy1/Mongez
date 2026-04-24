import 'package:flutter/material.dart';
import 'package:mongez/core/app_colors.dart';

class CustomFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final Widget? preIcon;
  final Widget? sufIcon;
  final bool obscureText;
  final TextInputType? keyboardType; // ← هنا
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const CustomFormField({
    super.key,
    this.controller,
    this.hintText = 'Find your favorite items',
    this.preIcon,
    this.sufIcon,
    this.obscureText = false,
    this.keyboardType, // ← هنا
    this.validator,
    this.onChanged,
  });

  @override
  State<CustomFormField> createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends State<CustomFormField> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isFocused ? 0.2 : 0.1),
                    blurRadius: _isFocused ? 10 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: field.hasError
                    ? Border.all(color: Colors.redAccent)
                    : null,
              ),
              child: TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType, // ← هنا
                onChanged: (value) {
                  field.didChange(value);
                  widget.onChanged?.call(value);
                },
                style: const TextStyle(color: Colors.black),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: AppColors.gray4),
                  prefixIcon: widget.preIcon,
                  suffixIcon: widget.sufIcon,
                  border: InputBorder.none,
                ),
              ),
            ),

            /// 🔴 Error خارج الفيلد
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
