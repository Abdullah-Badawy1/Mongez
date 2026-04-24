import 'package:flutter/material.dart';
import 'package:mongez/core/helpers.dart';
import 'package:mongez/features/checkout_feature/screens/addresses_screen.dart';
import 'package:mongez/features/checkout_feature/screens/cards_screen.dart';
import 'package:mongez/features/login_feature/screens/choose_account.dart';
import 'package:mongez/features/settings_feature/screens/settings_page.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';

import 'add_service_screen.dart';

class AccountScreen extends StatelessWidget {
  final bool isCustomer;

  const AccountScreen({super.key, required this.isCustomer});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: CustomAppBar(title: lang.account),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
            /// Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      theme.brightness == Brightness.dark ? 0.2 : 0.05,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundImage: const AssetImage(
                      "assets/images/person.png",
                    ),
                  ),
                  const SizedBox(width: 18),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppPrefs.username ?? lang.account,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text(AppPrefs.userRole ?? '', style: textTheme.bodySmall),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Cairo, Egypt",
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Icon(Icons.edit, size: 20, color: textTheme.bodySmall?.color),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (!isCustomer) ...[
              /// Rating
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "4.8",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text("120 ${lang.ratings}", style: textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),

              _AccountSection(
                icon: Icons.add_box_outlined,
                title: lang.addService,
                subtitle: lang.addServiceDesc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddServiceScreen()),
                  );
                },
              ),
            ],

            _AccountSection(
              icon: Icons.location_on_outlined,
              title: lang.addresses,
              subtitle: lang.addressesDesc,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedAddressPage()),
                );
              },
            ),

            if (isCustomer)
              _AccountSection(
                icon: Icons.credit_card,
                title: lang.paymentMethods,
                subtitle: lang.paymentMethodsDesc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CardsScreen()),
                  );
                },
              ),

            _AccountSection(
              icon: Icons.settings,
              title: lang.settings,
              subtitle: lang.settingsDesc,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),

                  ],
                ),
              ),
            ),

            /// Logout
            GestureDetector(
              onTap: () {
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
                        onPressed: () async {
                          await AppPrefs.clearTokens();
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChooseAccountTypeScreen(),
                            ),
                          );
                        },
                        child: Text(
                          lang.logout,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                margin: const EdgeInsets.only(bottom: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.error),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      lang.logout,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.15 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child: Icon(icon, color: colorScheme.primary),
        ),

        title: Text(
          title,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),

        subtitle: Text(subtitle, style: textTheme.bodySmall),

        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: textTheme.bodySmall?.color,
        ),

        onTap: onTap,
      ),
    );
  }
}
