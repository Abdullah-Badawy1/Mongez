import 'package:flutter/material.dart';

import '../api/api_error.dart';

/// Lightweight snackbar helpers — keeps every screen out of the
/// `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` boilerplate.
class Snack {
  Snack._();

  static void error(BuildContext context, Object error) {
    final apiErr =
        error is ApiError ? error : ApiError.from(error);
    _show(context, apiErr.message, Theme.of(context).colorScheme.error);
  }

  static void success(BuildContext context, String message) {
    _show(context, message, Colors.green.shade600);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, Theme.of(context).colorScheme.primary);
  }

  static void _show(BuildContext context, String message, Color color) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
