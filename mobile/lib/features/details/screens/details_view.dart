import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mongez/core/app_colors.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/features/checkout/screens/checkout_screen.dart';
import 'package:mongez/features/details/data/models/rating_model.dart';
import 'package:mongez/features/workers/data/models/worker_model.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/services/api_service.dart';
import 'package:mongez/services/services_locator.dart';
import 'package:mongez/widgets/favorite_button.dart';

class DetailsView extends StatefulWidget {
  final bool isCustomer;
  final WorkerModel worker;

  const DetailsView({
    super.key,
    required this.worker,
    required this.isCustomer,
  });

  @override
  State<DetailsView> createState() => _DetailsViewState();
}

class _DetailsViewState extends State<DetailsView> {
  List<RatingModel> _ratings = [];
  bool _isLoadingRatings = true;
  String? _ratingsError;

  @override
  void initState() {
    super.initState();
    _fetchRatings();
  }

  Future<void> _fetchRatings() async {
    try {
      final apiService = getIt<ApiService>();
      final data = await apiService.get(
        endPoint: Endpoints.workerRatings(widget.worker.id),
      );
      final ratingsList = (data['ratings'] as List<dynamic>?)
              ?.map((e) => RatingModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      if (!mounted) return;
      setState(() {
        _ratings = ratingsList;
        _isLoadingRatings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ratingsError = e.toString();
        _isLoadingRatings = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final w = widget.worker;

    final name = w.nameFor(locale).isNotEmpty ? w.nameFor(locale) : (w.username ?? '');
    final profession = w.professionFor(locale);
    final bio = w.bioFor(locale);
    final location = w.locationLabel(locale);
    final rate = _formatMoney(w.hourlyRate, w.currency, locale);
    final minCharge = _formatMoney(w.minimumCharge, w.currency, locale);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _Header(
            worker: w,
            isCustomer: widget.isCustomer,
            name: name,
            profession: profession,
            location: location,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _StatsRow(worker: w),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _InfoCard(
                children: [
                  if (rate != null)
                    _InfoRow(
                      icon: Icons.payments_outlined,
                      label: 'Hourly rate',
                      value: '$rate / hr',
                      highlight: true,
                    ),
                  if (minCharge != null)
                    _InfoRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Call-out fee',
                      value: minCharge,
                    ),
                  _InfoRow(
                    icon: Icons.bolt_outlined,
                    label: 'Avg. response',
                    value: '${w.responseTimeMinutes} min',
                  ),
                  _InfoRow(
                    icon: Icons.access_time_outlined,
                    label: 'Working hours',
                    value: w.workingHoursLabel(),
                  ),
                  if (w.languages.isNotEmpty)
                    _InfoRow(
                      icon: Icons.language_outlined,
                      label: 'Languages',
                      value: w.languages.map(_langName).join(' · '),
                    ),
                  if (w.serviceRadiusKm > 0)
                    _InfoRow(
                      icon: Icons.location_searching,
                      label: 'Service area',
                      value: 'within ${w.serviceRadiusKm} km',
                    ),
                ],
              ),
            ),
          ),
          if (w.specialtiesFor(locale).isNotEmpty)
            SliverToBoxAdapter(
              child: _Section(
                title: 'Specialties',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: w.specialtiesFor(locale).map((s) =>
                      _Tag(label: s),
                    ).toList(),
                  ),
                ),
              ),
            ),
          if (bio.isNotEmpty)
            SliverToBoxAdapter(
              child: _Section(
                title: lang.description,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Text(
                    bio,
                    style: tt.bodyMedium?.copyWith(height: 1.55),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _Section(
              title: lang.reviews,
              child: _buildReviewsContent(theme, cs, tt, lang),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: widget.isCustomer
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _BookCTA(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(worker: w),
                      ),
                    );
                  },
                  label: lang.bookNow,
                  rate: rate,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildReviewsContent(
    ThemeData theme,
    ColorScheme cs,
    TextTheme tt,
    S lang,
  ) {
    if (_isLoadingRatings) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_ratingsError != null || _ratings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            lang.noReviews,
            style: tt.bodyMedium?.copyWith(
              color: tt.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      itemCount: _ratings.length,
      itemBuilder: (context, index) {
        final rating = _ratings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: cs.primary.withValues(alpha: 0.1),
                      child: Text(
                        (rating.clientName ?? '?')[0].toUpperCase(),
                        style: tt.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rating.clientName ?? lang.anonymous,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        return Icon(
                          i < rating.stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: Colors.amber.shade700,
                        );
                      }),
                    ),
                  ],
                ),
                if (rating.review.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    rating.review,
                    style: tt.bodySmall?.copyWith(
                      height: 1.5,
                      color: tt.bodySmall?.color?.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String? _formatMoney(double? v, String currency, String locale) {
    if (v == null || v <= 0) return null;
    final fmt = NumberFormat.decimalPattern(locale);
    final body = fmt.format(v.round());
    final symbol = currency == 'EGP'
        ? (locale == 'ar' ? 'ج.م' : 'EGP')
        : currency;
    return '$body $symbol';
  }

  static String _langName(String code) {
    switch (code) {
      case 'ar': return 'Arabic';
      case 'en': return 'English';
      case 'fr': return 'French';
      default:    return code.toUpperCase();
    }
  }
}

// ─── Building blocks ────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final WorkerModel worker;
  final bool isCustomer;
  final String name;
  final String profession;
  final String location;
  const _Header({
    required this.worker,
    required this.isCustomer,
    required this.name,
    required this.profession,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.brand,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.maybePop(context),
                ),
                const Spacer(),
                if (isCustomer)
                  FavoriteButton(workerId: worker.userId ?? worker.id),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5), width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: worker.profileImage != null
                      ? Image.network(
                          worker.profileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => const Icon(
                            Icons.person, size: 40, color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.titleLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (worker.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified_rounded,
                                color: Colors.white, size: 22,
                              ),
                            ),
                        ],
                      ),
                      if (profession.isNotEmpty)
                        Text(
                          profession,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _GlassChip(
                            icon: Icons.star_rounded,
                            iconColor: Colors.amber.shade300,
                            text: '${worker.averageRating.toStringAsFixed(1)} '
                                '(${worker.completedJobs})',
                          ),
                          if (location.isNotEmpty)
                            _GlassChip(
                              icon: Icons.place_outlined,
                              text: location,
                            ),
                          if (worker.isFeatured)
                            _GlassChip(
                              icon: Icons.workspace_premium_outlined,
                              iconColor: Colors.amber.shade200,
                              text: 'Top rated',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String text;
  const _GlassChip({required this.icon, required this.text, this.iconColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final WorkerModel worker;
  const _StatsRow({required this.worker});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    Widget cell(String label, String value, IconData icon, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(value, style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800, color: color, fontSize: 16,
              )),
              const SizedBox(height: 2),
              Text(label, style: tt.bodySmall?.copyWith(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7),
              )),
            ],
          ),
        ),
      );
    }
    return Row(
      children: [
        cell('Complete', '${worker.completionRate.round()}%',
            Icons.check_circle_outline, AppColors.success),
        const SizedBox(width: 10),
        cell('Accept', '${worker.acceptRate.round()}%',
            Icons.task_alt_outlined, AppColors.primary),
        const SizedBox(width: 10),
        cell('Experience', '${worker.experienceYears}y',
            Icons.workspace_premium_outlined, AppColors.highlight),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  const _InfoRow({
    required this.icon, required this.label, required this.value,
    this.highlight = false,
  });
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontSize: 13.5,
              ),
            ),
          ),
          Text(
            value,
            style: tt.titleSmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: highlight ? cs.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              title,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _BookCTA extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final String? rate;
  const _BookCTA({required this.onTap, required this.label, this.rate});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: AppGradients.brand,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            if (rate != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rate!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'per hour',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
