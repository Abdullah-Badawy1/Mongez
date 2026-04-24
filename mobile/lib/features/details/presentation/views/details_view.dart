import 'package:flutter/material.dart';
import 'package:mongez/features/checkout_feature/screens/checkout_screen.dart';
import 'package:mongez/features/details/presentation/views/widgets/custom_sup_title.dart';
import 'package:mongez/features/details/presentation/views/widgets/custom_title.dart';
import 'package:mongez/features/home_feature/model/service_item/service_item.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';
import 'package:mongez/widgets/custom_button.dart';

class DetailsView extends StatelessWidget {
  final bool isCustomer;
  final ServiceItem item;

  const DetailsView({super.key, required this.item, required this.isCustomer});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: CustomAppBar(title: lang.details),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          /// Image
          SliverToBoxAdapter(
            child: SizedBox(
              width: double.infinity,
              height: 280,
              child: Image.asset(item.cover, fit: BoxFit.cover),
            ),
          ),

          /// Rating + Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        "4.9 (6.8K reviews)",
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.address,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          CustomSupTitle(supTitle: lang.info),

          /// Worker
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage(item.workerImage),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.verified, size: 32, color: colorScheme.primary),
                ],
              ),
            ),
          ),

          CustomSupTitle(supTitle: lang.description),

          /// Description
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(item.description, style: textTheme.bodyMedium),
            ),
          ),

          CustomSupTitle(supTitle: lang.address),

          /// Address
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.address, style: textTheme.bodyMedium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          lang.viewOnMap,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          CustomTitle(title: lang.reviews),

          /// Reviews
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: AssetImage(item.workerImage),
                        ),
                        const Spacer(),
                        Text(
                          "Ahmed Tantawy",
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.star, size: 18, color: Colors.amber),
                        Icon(Icons.star, size: 18, color: Colors.amber),
                        Icon(Icons.star, size: 18, color: Colors.amber),
                        Icon(Icons.star, size: 18, color: Colors.amber),
                        Icon(Icons.star, size: 18, color: Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(lang.reviewExample, style: textTheme.bodySmall),
                  ],
                ),
              );
            }, childCount: 3),
          ),

          /// Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                children: [
                  CustomButton(
                    text: isCustomer ? lang.bookNow : lang.delete,
                    onPressed: () {
                      if (isCustomer) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                                workerId: item.workerId,
                                categoryId: item.categoryId,
                              ),
                          ),
                        );
                      }
                    },
                    backgroundColor: colorScheme.primary,
                    textColor: colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
