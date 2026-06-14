import 'package:flutter/material.dart';

class CustomFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final Widget? preIcon;
  final Widget? sufIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const CustomFormField({
    super.key,
    this.controller,
    this.hintText = '',
    this.preIcon,
    this.sufIcon,
    this.obscureText = false,
    this.keyboardType,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return FormField<String>(
      validator: widget.validator,
      builder: (field) {
        final hasError = field.hasError;
        final borderColor = hasError
            ? cs.error
            : _isFocused
                ? cs.primary
                : cs.outline;
        final borderWidth = (_isFocused || hasError) ? 1.6 : 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                onChanged: (v) {
                  field.didChange(v);
                  widget.onChanged?.call(v);
                },
                style: tt.bodyLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: cs.primary,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  hintText: widget.hintText,
                  hintStyle: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                  prefixIcon: widget.preIcon,
                  suffixIcon: widget.sufIcon,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 14, color: cs.error),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        field.errorText!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
