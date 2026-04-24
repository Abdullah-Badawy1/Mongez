import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/bloc/orders/orders_cubit.dart';
import 'package:mongez/core/bloc/orders/orders_state.dart';
import 'package:mongez/core/models/order_model.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrdersCubit()..loadOrders(),
      child: const _RequestsBody(),
    );
  }
}

class _RequestsBody extends StatelessWidget {
  const _RequestsBody();

  Color _statusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return cs.primary;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
      case 'REJECTED':
        return cs.error;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(S lang, String status) {
    switch (status) {
      case 'PENDING':
        return lang.pending;
      case 'ACCEPTED':
        return lang.confirmed;
      case 'COMPLETED':
        return lang.completed;
      case 'CANCELLED':
      case 'REJECTED':
        return lang.canceled;
      default:
        return status;
    }
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: CustomAppBar(title: lang.requests),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<OrdersCubit, OrdersState>(
        listener: (context, state) {
          if (state is OrderActionSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is OrdersError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ));
          }
        },
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders =
              state is OrdersLoaded ? state.orders : <OrderModel>[];

          if (orders.isEmpty) {
            return Center(child: Text(lang.requests));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final statusColor = _statusColor(context, order.status);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.serviceCategoryName,
                            style: textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(lang, order.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Client: ${order.clientName}',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lang.date}: ${_formatDate(order.createdAt)}',
                      style: textTheme.bodySmall,
                    ),
                    if (order.isPending) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.error),
                            onPressed: () => context
                                .read<OrdersCubit>()
                                .rejectOrder(order.id),
                            child: Text(lang.delete),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => context
                                .read<OrdersCubit>()
                                .acceptOrder(order.id),
                            child: Text(lang.confirmed),
                          ),
                        ],
                      ),
                    ],
                    if (order.isAccepted) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ElevatedButton(
                          onPressed: () => context
                              .read<OrdersCubit>()
                              .completeOrder(order.id),
                          child: Text(lang.completed),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
