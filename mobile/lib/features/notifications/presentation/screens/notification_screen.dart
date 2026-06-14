import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/auth/bloc/login_cubit/auth_cubit.dart';
import 'package:mongez/features/notifications/data/models/notification_model.dart';
import 'package:mongez/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mongez/features/orders/domain/order_repository.dart';
import 'package:mongez/features/orders/presentation/screens/order_details_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/services/services_locator.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(lang.notifications),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is NotificationSuccess && state.notifications.any((n) => !n.isRead)) {
                return TextButton(
                  onPressed: () => context.read<NotificationCubit>().markAllAsRead(),
                  child: Text(lang.markAllRead),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationInitial) {
            context.read<NotificationCubit>().refresh();
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationSuccess) {
            final notifications = state.notifications;
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(lang.noNotifications, style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<NotificationCubit>().refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) => _NotificationTile(notif: notifications[index]),
              ),
            );
          }
          if (state is NotificationFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.errorMessage, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<NotificationCubit>().refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  const _NotificationTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isUnread = !notif.isRead;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isUnread
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isUnread ? Icons.notifications : Icons.notifications_none,
          color: isUnread ? theme.colorScheme.primary : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(
        notif.title,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notif.message,
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (notif.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatTime(notif.createdAt!),
              style: textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade400,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
      trailing: isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            )
          : null,
      onTap: () {
        if (isUnread) {
          context.read<NotificationCubit>().markAsRead(notif.id);
        }
        if (notif.orderId != null) {
          _navigateToOrder(context, notif.orderId!);
        }
      },
    );
  }

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return dateStr;
    }
  }

  void _navigateToOrder(BuildContext context, int orderId) async {
    final repo = getIt.get<OrderRepository>();
    final result = await repo.getOrderById(orderId);
    result.fold(
      (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorOccurred)),
        );
      },
      (order) {
        if (!context.mounted) return;
        final authState = context.read<LoginCubit>().state;
        final isCustomer = authState is LoginSuccess && authState.auth.user?.role == 'client';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(order: order, isCustomer: isCustomer),
          ),
        );
      },
    );
  }
}
