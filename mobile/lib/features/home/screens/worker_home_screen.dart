import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/account/screens/add_service_screen.dart';
import 'package:mongez/features/auth/models/user.dart';
import 'package:mongez/features/orders/data/models/order_model.dart';
import 'package:mongez/features/orders/presentation/cubit/technician_orders_cubit.dart';
import 'package:mongez/features/orders/presentation/screens/order_details_screen.dart';
import 'package:mongez/features/orders/presentation/widgets/order_card.dart';
import 'package:mongez/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/features/workers/data/models/worker_stats.dart';
import 'package:mongez/features/workers/presentation/cubit/worker_stats_cubit.dart';

/// Worker home — purpose-built for the role.
///
/// Layout, top-down:
///   1. Header card — name, governorate, Verified chip + an
///      Online/Offline switch tied to WorkerProfile.is_available.
///   2. "No profile yet" CTA — only for workers who registered but
///      never completed AddService; tap → AddServiceScreen.
///   3. Stats grid — completed jobs (lifetime + this-month), pending
///      requests, average rating. Live from /api/workers/me/stats/.
///   4. My service summary — profession (en + ar).
///   5. Incoming requests feed — PENDING orders sorted first, tap →
///      OrderDetailsScreen.
///   6. Recent reviews — last 5 customer ratings with stars + text.
///
/// **No FAB to place an order** — the backend rejects non-client
/// roles with a 403 "Only clients can create orders", so we don't
/// surface a CTA that would just dead-end.
class WorkerHomeScreen extends StatefulWidget {
  final User user;
  const WorkerHomeScreen({super.key, required this.user});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  // Cached so dispose() doesn't have to touch context — back-pop safe.
  TechnicianOrdersCubit? _ordersCubit;
  WorkerStatsCubit? _statsCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ordersCubit == null) {
      _ordersCubit = context.read<TechnicianOrdersCubit>();
      _ordersCubit!.startPolling();
    }
    if (_statsCubit == null) {
      _statsCubit = context.read<WorkerStatsCubit>();
      _statsCubit!.load();
    }
  }

  @override
  void dispose() {
    _ordersCubit?.stopPolling();
    _ordersCubit = null;
    _statsCubit = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Re-fetch stats whenever the orders cubit emits — covers Accept,
      // Reject, Mark-finished. Counters then refresh without waiting
      // for the 30 s WorkerStatsCubit poll.
      body: BlocListener<TechnicianOrdersCubit, TechnicianOrdersState>(
        listener: (_, __) => _statsCubit?.load(),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _ordersCubit?.getOrders();
              await _statsCubit?.load();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: const [
                _WorkerHeaderCard(),
                SizedBox(height: 16),
                _NoProfileCta(),
                _StatsGrid(),
                _ServiceSummary(),
                _IncomingRequests(),
                _RecentReviews(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkerHeaderCard extends StatelessWidget {
  const _WorkerHeaderCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (ctx, profileState) {
        final profile =
            profileState is ProfileSuccess ? profileState.profile : null;
        final displayName = profile?.displayName ?? profile?.username ?? '';
        final governorate = profile?.governorateLabel ?? '';
        final city = profile?.city ?? '';
        final locationParts = [
          if (governorate.isNotEmpty) governorate,
          if (city.isNotEmpty) city,
        ];

        return BlocBuilder<WorkerStatsCubit, WorkerStatsState>(
          builder: (ctx, statsState) {
            final stats = statsState is WorkerStatsSuccess ? statsState.stats : null;
            final isAvailable = stats?.isAvailable ?? false;

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.78)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (locationParts.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: cs.onPrimary.withValues(alpha: 0.78),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      locationParts.join(' · '),
                                      style: tt.bodyMedium?.copyWith(
                                        color:
                                            cs.onPrimary.withValues(alpha: 0.78),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (stats?.isVerified ?? false)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.onPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  size: 14, color: cs.onPrimary),
                              const SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (stats != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.onPrimary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? const Color(0xFF34D399)
                                  : Colors.white60,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isAvailable
                                  ? 'Available — clients can book you now'
                                  : "Offline — you won't receive new bookings",
                              style:
                                  tt.bodySmall?.copyWith(color: cs.onPrimary),
                            ),
                          ),
                          Switch(
                            value: isAvailable,
                            onChanged: (v) => ctx
                                .read<WorkerStatsCubit>()
                                .toggleAvailability(v),
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFF34D399),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor:
                                cs.onPrimary.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _NoProfileCta extends StatelessWidget {
  const _NoProfileCta();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerStatsCubit, WorkerStatsState>(
      builder: (ctx, state) {
        if (state is! WorkerStatsNoProfile) return const SizedBox.shrink();
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: cs.error, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finish setting up your worker profile',
                      style: tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pick a service & experience so clients can find you.',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => const AddServiceScreen(),
                  ),
                ),
                child: const Text('Set up'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerStatsCubit, WorkerStatsState>(
      builder: (ctx, state) {
        if (state is! WorkerStatsSuccess) return const SizedBox.shrink();
        final s = state.stats;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Completed',
                  value: '${s.completedJobs}',
                  subtitle: 'this month: ${s.thisMonthCompleted}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.inbox_outlined,
                  label: 'Pending',
                  value: '${s.pendingRequests}',
                  subtitle: 'awaiting your reply',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.star_rate_rounded,
                  label: 'Rating',
                  value: s.averageRating.toStringAsFixed(1),
                  subtitle: '${s.recentReviews.length} recent',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ServiceSummary extends StatelessWidget {
  const _ServiceSummary();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerStatsCubit, WorkerStatsState>(
      builder: (ctx, state) {
        if (state is! WorkerStatsSuccess) return const SizedBox.shrink();
        final s = state.stats;
        final theme = Theme.of(ctx);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.handyman_rounded,
                    color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My service',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.profession.isNotEmpty ? s.profession : '—',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (s.professionAr.isNotEmpty)
                      Text(
                        s.professionAr,
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IncomingRequests extends StatelessWidget {
  const _IncomingRequests();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                if (state is! TechnicianOrdersSuccess) return const SizedBox();
                final pending = state.orders
                    .where((o) => o.status == OrderStatus.pending)
                    .length;
                if (pending == 0) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                context,
                icon: Icons.cloud_off_rounded,
                title: 'Could not load requests',
                subtitle: state.errorMessage,
              );
            }
            if (state is TechnicianOrdersEmpty) {
              return _emptyState(
                context,
                icon: Icons.inbox_rounded,
                title: 'No requests yet',
                subtitle:
                    'When a client books your service it will land here.',
              );
            }
            if (state is TechnicianOrdersSuccess) {
              final orders = [...state.orders]..sort((a, b) {
                  const pending = OrderStatus.pending;
                  if (a.status == pending && b.status != pending) return -1;
                  if (b.status == pending && a.status != pending) return 1;
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
    );
  }

  Widget _emptyState(
    BuildContext context, {
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

class _RecentReviews extends StatelessWidget {
  const _RecentReviews();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerStatsCubit, WorkerStatsState>(
      builder: (ctx, state) {
        if (state is! WorkerStatsSuccess) return const SizedBox.shrink();
        final reviews = state.stats.recentReviews;
        if (reviews.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent reviews',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final WorkerStatsReview r in reviews) _ReviewTile(review: r),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final WorkerStatsReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                child: Text(
                  review.clientUsername.isNotEmpty
                      ? review.clientUsername[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.clientUsername,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  final filled = i < review.stars;
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),
          if (review.review.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.review,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
