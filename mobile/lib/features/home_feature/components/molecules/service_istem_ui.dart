import 'package:flutter/material.dart';
import 'package:mongez/features/checkout_feature/screens/checkout_screen.dart';
import 'package:mongez/features/details/presentation/views/details_view.dart';
import 'package:mongez/features/home_feature/model/service_item/service_item.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_button.dart';

class ServiceCard extends StatelessWidget {
  final bool isCustomer;
  final ServiceItem service;

  const ServiceCard({
    super.key,
    required this.service,
    required this.isCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.2 : 0.08,
            ),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.asset(
              service.cover,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),

                Text(
                  service.description,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: AssetImage(service.workerImage),
                            radius: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.serviceProvider,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  service.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: isCustomer ? lang.book : lang.edit,
                      onPressed: () {
                        if (isCustomer) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailsView(
                                item: service,
                                isCustomer: isCustomer,
                              ),
                            ),
                          );
                        }
                      },
                      width: 100,
                      height: 45,
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
