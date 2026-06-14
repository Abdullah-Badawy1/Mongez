import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/orders/data/models/order_model.dart';
import 'package:mongez/features/orders/presentation/cubit/customer_orders_cubit.dart';
import 'package:mongez/features/orders/presentation/cubit/technician_orders_cubit.dart';
import 'package:mongez/features/orders/presentation/screens/rate_order_screen.dart';
import 'package:mongez/features/orders/presentation/widgets/status_badge.dart';
import 'package:mongez/generated/l10n.dart';

class OrderCard extends StatefulWidget {
  final OrderModel order;
  final bool isCustomer;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.isCustomer,
    this.onTap,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isAccepting = false;
  bool _isRejecting = false;
  bool _isMarkingFinished = false;
  bool _isCancelling = false;
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.order.categoryName ?? 'Order #${widget.order.id}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusBadge(status: widget.order.status, isCustomer: widget.isCustomer),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.order.description, style: textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  widget.isCustomer
                      ? '${lang.serviceProvider}: ${widget.order.workerName ?? ""}'
                      : '${lang.customer}: ${widget.order.clientName ?? ""}',
                  style: textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  _formatDate(widget.order.createdAt),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActions(context),
            if (widget.isCustomer && widget.order.status == OrderStatus.completed)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: widget.order.isRated
                    ? _buildRatedBanner(context)
                    : SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToRateOrder(context),
                          icon: const Icon(Icons.star_half, size: 18),
                          label: Text(S.of(context).rateOrder),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatedBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.of(context).ratingSubmitted,
              style: TextStyle(color: Colors.green.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToRateOrder(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RateOrderScreen(order: widget.order),
      ),
    );
    if (result == true && mounted) {
      context.read<CustomerOrdersCubit>().getOrders();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildActions(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);

    if (widget.isCustomer) {
      if (widget.order.status == OrderStatus.pending) {
        return Row(
          children: [
            Icon(Icons.hourglass_empty, size: 16, color: Colors.orange),
            const SizedBox(width: 6),
            Text(lang.pending, style: TextStyle(color: Colors.orange, fontSize: 13)),
            const Spacer(),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: _isCancelling ? null : () => _showCancelDialog(context),
              child: _isCancelling
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(lang.cancel),
            ),
          ],
        );
      }
      if (widget.order.status == OrderStatus.accepted) {
        return Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${widget.order.workerName ?? lang.serviceProvider} accepted your request',
                style: TextStyle(color: Colors.green.shade700, fontSize: 13),
              ),
            ),
          ],
        );
      }
      if (widget.order.status == OrderStatus.waitingConfirmation) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.purple),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(lang.workerMarkedFinished, style: TextStyle(color: Colors.purple.shade700, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : () => _doConfirmCompletion(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isConfirming
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(lang.confirmCompletion),
              ),
            ),
          ],
        );
      }
      if (widget.order.status == OrderStatus.completed) {
        return Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Text(lang.completed, style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
          ],
        );
      }
      if (widget.order.status == OrderStatus.rejected) {
        return Row(
          children: [
            Icon(Icons.cancel, size: 16, color: Colors.red),
            const SizedBox(width: 6),
            Expanded(
              child: Text(lang.rejectedByWorker, style: TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ],
        );
      }
      if (widget.order.status == OrderStatus.cancelled) {
        return Row(
          children: [
            Icon(Icons.cancel, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(lang.cancelledByYou, style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          ],
        );
      }
    } else {
      if (widget.order.status == OrderStatus.pending) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isAccepting ? null : () => _doAccept(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isAccepting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(lang.accept),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isRejecting ? null : () => _doReject(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRejecting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(lang.cancel),
              ),
            ),
          ],
        );
      }
      if (widget.order.status == OrderStatus.accepted) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Text(lang.inProgress, style: TextStyle(color: Colors.blue.shade700, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isMarkingFinished ? null : () => _doMarkFinished(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isMarkingFinished
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(lang.markAsFinished),
              ),
            ),
          ],
        );
      }
      if (widget.order.status == OrderStatus.waitingConfirmation) {
        return Row(
          children: [
            Icon(Icons.hourglass_top, size: 16, color: Colors.purple),
            const SizedBox(width: 6),
            Expanded(
              child: Text(lang.waitingConfirmation, style: TextStyle(color: Colors.purple, fontSize: 13)),
            ),
          ],
        );
      }
      if (widget.order.status == OrderStatus.completed) {
        return Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Text(lang.completed, style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
          ],
        );
      }
      if (widget.order.status == OrderStatus.rejected) {
        return Row(
          children: [
            Icon(Icons.cancel, size: 16, color: Colors.red),
            const SizedBox(width: 6),
            Expanded(
              child: Text(lang.rejectedByYou, style: TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ],
        );
      }
      if (widget.order.status == OrderStatus.cancelled) {
        return Row(
          children: [
            Icon(Icons.cancel, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(lang.cancelledByCustomer, style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          ],
        );
      }
    }

    return const SizedBox();
  }

  Future<void> _doAccept(BuildContext context) async {
    setState(() => _isAccepting = true);
    await context.read<TechnicianOrdersCubit>().acceptOrder(widget.order.id);
  }

  Future<void> _doReject(BuildContext context) async {
    setState(() => _isRejecting = true);
    await context.read<TechnicianOrdersCubit>().rejectOrder(widget.order.id);
  }

  Future<void> _doMarkFinished(BuildContext context) async {
    setState(() => _isMarkingFinished = true);
    await context.read<TechnicianOrdersCubit>().markAsFinished(widget.order.id);
  }

  Future<void> _doConfirmCompletion(BuildContext context) async {
    setState(() => _isConfirming = true);
    await context.read<CustomerOrdersCubit>().confirmCompletion(widget.order.id);
  }

  void _showCancelDialog(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.cancelRequest),
        content: Text(lang.cancelRequestConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isCancelling = true);
              context.read<CustomerOrdersCubit>().cancelOrder(widget.order.id);
            },
            child: Text(lang.yes, style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
