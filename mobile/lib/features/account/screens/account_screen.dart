import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/checkout/screens/addresses_screen.dart';
import 'package:mongez/features/checkout/screens/cards_screen.dart';
import 'package:mongez/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/features/settings/screens/settings_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/services/navigation_service.dart';
import 'package:mongez/widgets/custom_app_bar.dart';
import 'add_service_screen.dart';

class AccountScreen extends StatelessWidget {
  final bool isCustomer;

  const AccountScreen({super.key, required this.isCustomer});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      appBar: CustomAppBar(title: lang.account),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final profile = state is ProfileSuccess ? state.profile : null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _ProfileCard(
                username: profile?.username ?? '...',
                phone: profile?.phone ?? '',
                address: profile?.address ?? '',
                imageUrl: profile?.profileImage,
              ),
              const SizedBox(height: 20),
              if (!isCustomer) ...[
                _StatTile(
                  rating: profile?.averageRating ?? 0,
                  jobs: profile?.completedJobs ?? 0,
                  label: lang.ratings,
                ),
                const SizedBox(height: 12),
                _AccountTile(
                  icon: Icons.add_business_rounded,
                  title: lang.addService,
                  subtitle: lang.addServiceDesc,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddServiceScreen(),
                    ),
                  ),
                ),
              ],
              _AccountTile(
                icon: Icons.location_on_outlined,
                title: lang.addresses,
                subtitle: lang.addressesDesc,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SavedAddressPage(),
                  ),
                ),
              ),
              if (isCustomer)
                _AccountTile(
                  icon: Icons.credit_card_rounded,
                  title: lang.paymentMethods,
                  subtitle: lang.paymentMethodsDesc,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CardsScreen()),
                  ),
                ),
              _AccountTile(
                icon: Icons.settings_outlined,
                title: lang.settings,
                subtitle: lang.settingsDesc,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, lang, cs, tt),
                icon: Icon(Icons.logout_rounded, color: cs.error),
                label: Text(
                  lang.logout,
                  style: tt.titleMedium?.copyWith(
                    color: cs.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: cs.error.withValues(alpha: 0.4), width: 1.2),
                  backgroundColor: cs.error.withValues(alpha: 0.06),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmLogout(
      BuildContext context, S lang, ColorScheme cs, TextTheme tt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.logout),
        content: Text(lang.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              NavigationService.logout(context);
            },
            child: Text(
              lang.logout,
              style: tt.labelLarge?.copyWith(color: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String username;
  final String phone;
  final String address;
  final String? imageUrl;

  const _ProfileCard({
    required this.username,
    required this.phone,
    required this.address,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer,
            cs.primaryContainer.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surface,
              border: Border.all(
                color: cs.outline.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _personFallback(cs),
                  )
                : _personFallback(cs),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: tt.titleLarge?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.phone_rounded,
                        size: 14,
                        color:
                            cs.onPrimaryContainer.withValues(alpha: 0.75)),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: tt.bodySmall?.copyWith(
                        color:
                            cs.onPrimaryContainer.withValues(alpha: 0.75),
                      ),
                    ),
                  ]),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on_rounded,
                        size: 14,
                        color:
                            cs.onPrimaryContainer.withValues(alpha: 0.75)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color:
                              cs.onPrimaryContainer.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),
          Icon(Icons.edit_rounded,
              size: 18, color: cs.onPrimaryContainer.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}

Widget _personFallback(ColorScheme cs) => Container(
      color: cs.primaryContainer,
      alignment: Alignment.center,
      child: Icon(Icons.person_rounded,
          size: 32, color: cs.onPrimaryContainer),
    );

class _StatTile extends StatelessWidget {
  final double rating;
  final int jobs;
  final String label;

  const _StatTile({
    required this.rating,
    required this.jobs,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.tertiary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.star_rounded, color: cs.tertiary, size: 26),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text('$jobs $label', style: tt.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: cs.outline.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          tileColor: Colors.transparent,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.onPrimaryContainer, size: 22),
          ),
          title: Text(
            title,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle, style: tt.bodySmall),
          ),
          trailing: Icon(
            isRtl
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
