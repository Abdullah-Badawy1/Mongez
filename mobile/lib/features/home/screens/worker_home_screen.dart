import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/auth/models/user.dart';
import 'package:mongez/features/categories/screens/categories_screen.dart';
import 'package:mongez/features/orders/data/models/order_model.dart';
import 'package:mongez/features/orders/presentation/cubit/technician_orders_cubit.dart';
import 'package:mongez/features/orders/presentation/screens/order_details_screen.dart';
import 'package:mongez/features/orders/presentation/widgets/order_card.dart';
import 'package:mongez/features/profile/presentation/cubit/profile_cubit.dart';

/// Worker home — built for the role.
///
/// Replaces the customer-flavoured browse-workers list (which doesn't
/// make sense for someone who *is* a worker) with:
///
///  1. a header card showing the worker's name, governorate, rating
///     and completed-jobs count, pulled from `/api/users/me/` via
///     [ProfileCubit];
///  2. a "Place an order yourself" CTA — workers can act as customers
///     when they need a service, so we surface a clear icon button
///     that opens the categories screen in customer mode;
///  3. a live list of **incoming requests** — PENDING orders assigned
///     to this worker, with tap-through to the order detail screen
///     where they can accept / reject. Backed by
///     [TechnicianOrdersCubit] which already polls every 30 s, so the
///     list refreshes itself without the worker pulling.
class WorkerHomeScreen extends StatefulWidget {
  final User user;
  const WorkerHomeScreen({super.key, required this.user});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  // Cached so dispose() doesn't have to touch context — back-pop safe.
  TechnicianOrdersCubit? _ordersCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ordersCubit == null) {
      _ordersCubit = context.read<TechnicianOrdersCubit>();
      _ordersCubit!.startPolling();
    }
  }

  @override
  void dispose() {
    _ordersCubit?.stopPolling();
    _ordersCubit = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            // Categories screen in customer mode lets workers act
            // as clients and request someone else's service.
            builder: (_) => const CategoriesScreen(isCustomer: true),
          ),
        ),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Need a service?'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _ordersCubit?.getOrders();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _WorkerHeaderCard(user: widget.user),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Incoming requests',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  BlocBuilder<TechnicianOrdersCubit, TechnicianOrdersState>(
                    builder: (ctx, state) {
                      if (state is! TechnicianOrdersSuccess) {
                        return const SizedBox();
                      }
                      final pending = state.orders
                          .where((o) => o.status == OrderStatus.pending)
                          .length;
                      if (pending == 0) return const SizedBox();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pending new',
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              BlocBuilder<TechnicianOrdersCubit, TechnicianOrdersState>(
                builder: (ctx, state) {
                  if (state is TechnicianOrdersInitial ||
                      state is TechnicianOrdersLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (state is TechnicianOrdersFailure) {
                    return _emptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load requests',
                      subtitle: state.errorMessage,
                    );
                  }
                  if (state is TechnicianOrdersEmpty) {
                    return _emptyState(
                      icon: Icons.inbox_rounded,
                      title: 'No requests yet',
                      subtitle:
                          'When a client books your service it will land here.',
                    );
                  }
                  if (state is TechnicianOrdersSuccess) {
                    // Sort PENDING first so the worker sees what needs
                    // their attention without scrolling.
                    final orders = [...state.orders]..sort((a, b) {
                        const pending = OrderStatus.pending;
                        if (a.status == pending && b.status != pending) {
                          return -1;
                        }
                        if (b.status == pending && a.status != pending) {
                          return 1;
                        }
                        return 0;
                      });
                    return Column(
                      children: [
                        for (final OrderModel order in orders)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: OrderCard(
                              order: order,
                              isCustomer: false,
                              onTap: () => Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailsScreen(
                                    order: order,
                                    isCustomer: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 56, color: cs.onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(title, style: tt.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _WorkerHeaderCard extends StatelessWidget {
  final User user;
  const _WorkerHeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (ctx, state) {
        final profile = state is ProfileSuccess ? state.profile : null;
        final displayName = profile?.displayName ?? user.username ?? '';
        final governorate = profile?.governorateLabel ?? '';
        final rating = profile?.averageRating ?? 0;
        final completedJobs = profile?.completedJobs ?? 0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary,
                cs.primary.withValues(alpha: 0.78),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onPrimary.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: tt.headlineSmall?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (governorate.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: cs.onPrimary.withValues(alpha: 0.78),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      governorate,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onPrimary.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.star_rounded,
                    label: 'Rating',
                    value: rating.toStringAsFixed(1),
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Jobs done',
                    value: '$completedJobs',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.onPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.onPrimary, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onPrimary.withValues(alpha: 0.78),
                ),
              ),
              Text(
                value,
                style: tt.titleMedium?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
