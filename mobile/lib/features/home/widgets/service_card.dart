import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mongez/features/checkout/screens/checkout_screen.dart';
import 'package:mongez/features/details/screens/details_view.dart';
import 'package:mongez/features/workers/data/models/worker_model.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/favorite_button.dart';

class ServiceCard extends StatelessWidget {
  final bool isCustomer;
  final WorkerModel worker;

  const ServiceCard({
    super.key,
    required this.worker,
    required this.isCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final dim = tt.bodySmall?.color?.withValues(alpha: 0.65);

    final name = worker.nameFor(locale).isNotEmpty
        ? worker.nameFor(locale)
        : (worker.username ?? '');
    final profession = worker.professionFor(locale);
    final bio = worker.bioFor(locale);
    final location = worker.locationLabel(locale);
    final rateLabel = _formatRate(worker.hourlyRate, worker.currency, locale);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.35 : 0.05,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Banner(
              worker: worker,
              isCustomer: isCustomer,
              cs: cs,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 38, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name + verified badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16.5,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      if (worker.isVerified)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: cs.primary,
                          ),
                        ),
                    ],
                  ),
                  if (profession.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      profession,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Meta row: rating · location · experience
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MetaChip(
                        icon: Icons.star_rounded,
                        iconColor: Colors.amber.shade700,
                        label: worker.averageRating.toStringAsFixed(1),
                        sub: ' (${worker.completedJobs})',
                        tt: tt,
                      ),
                      if (location.isNotEmpty)
                        _MetaChip(
                          icon: Icons.location_on_outlined,
                          iconColor: dim,
                          label: location,
                          tt: tt,
                        ),
                      if (worker.experienceYears > 0)
                        _MetaChip(
                          icon: Icons.work_outline,
                          iconColor: dim,
                          label: '${worker.experienceYears} ${lang.years}',
                          tt: tt,
                        ),
                    ],
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(
                        height: 1.45,
                        fontSize: 13,
                        color: tt.bodySmall?.color?.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (rateLabel != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rateLabel,
                                  style: tt.titleSmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  lang.years.toLowerCase() == 'years'
                                      ? 'per hour'
                                      : 'بالساعة',
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.primary.withValues(alpha: 0.8),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (rateLabel != null) const SizedBox(width: 10),
                      Expanded(
                        flex: rateLabel == null ? 1 : 2,
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              if (isCustomer) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CheckoutScreen(worker: worker),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailsView(
                                      worker: worker,
                                      isCustomer: isCustomer,
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isCustomer ? lang.bookNow : lang.edit,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _formatRate(double? rate, String currency, String locale) {
    if (rate == null || rate <= 0) return null;
    final fmt = NumberFormat.decimalPattern(locale);
    final body = fmt.format(rate.round());
    // Egypt: prefer "EGP" / "ج.م" symbol convention.
    final symbol = currency == 'EGP'
        ? (locale == 'ar' ? 'ج.م' : 'EGP')
        : currency;
    return locale == 'ar' ? '$body $symbol' : '$body $symbol';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? sub;
  final TextTheme tt;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.tt,
    this.iconColor,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 130),
          child: Text(
            sub == null ? label : '$label${sub!}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final WorkerModel worker;
  final bool isCustomer;
  final ColorScheme cs;

  const _Banner({
    required this.worker,
    required this.isCustomer,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withValues(alpha: 0.42),
                    cs.primary.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
          // Availability pill
          Positioned(
            top: 10,
            left: 12,
            child: _AvailabilityPill(isAvailable: worker.isAvailable),
          ),
          if (isCustomer)
            Positioned(
              top: 6,
              right: 6,
              child: FavoriteButton(workerId: worker.userId ?? worker.id),
            ),
          // Avatar overlapping bottom-left of banner
          Positioned(
            bottom: -30,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: cs.primary.withValues(alpha: 0.08),
                child: ClipOval(
                  child: worker.profileImage != null
                      ? Image.network(
                          worker.profileImage!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) =>
                              Icon(Icons.person, size: 26, color: cs.primary),
                        )
                      : Icon(Icons.person, size: 26, color: cs.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityPill({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable ? 'Available' : 'Busy',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
