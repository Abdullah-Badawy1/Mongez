import 'package:flutter/material.dart';
import 'package:mongez/features/orders/data/models/order_model.dart';
import 'package:mongez/generated/l10n.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool isCustomer;

  const StatusBadge({super.key, required this.status, this.isCustomer = true});

  Color _color() {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.waitingConfirmation:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.rejected:
        return Colors.red;
      case OrderStatus.cancelled:
        return Colors.grey;
    }
  }

  String _label(S lang) {
    switch (status) {
      case OrderStatus.pending:
        return lang.pending;
      case OrderStatus.accepted:
        return lang.confirmed;
      case OrderStatus.inProgress:
        return lang.inProgress;
      case OrderStatus.waitingConfirmation:
        return lang.waitingConfirmation;
      case OrderStatus.completed:
        return lang.completed;
      case OrderStatus.rejected:
        return isCustomer ? lang.rejectedByWorker : lang.rejected;
      case OrderStatus.cancelled:
        return isCustomer ? lang.cancelledByYou : lang.rejected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(lang),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
