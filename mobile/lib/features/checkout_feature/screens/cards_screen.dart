import 'package:flutter/material.dart';
import 'package:mongez/features/checkout_feature/components/molecules/cards.dart';
import 'package:mongez/features/checkout_feature/screens/add_card_screen.dart';
import 'package:mongez/features/checkout_feature/screens/addresses_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';
import 'package:mongez/widgets/custom_button.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  AddressModel? selectedItem;

  final List<AddressModel> addresses = [
    AddressModel(title: null, address: "**** **** **** 4281", isDefault: true),
    AddressModel(title: null, address: "**** **** **** 9012"),
    AddressModel(title: null, address: "**** **** **** 6677"),
  ];

  @override
  void initState() {
    super.initState();
    selectedItem = addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: CustomAppBar(title: lang.myCards),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Divider(
                    thickness: 1,
                    color: textTheme.bodySmall?.color?.withOpacity(0.3),
                  ),
                  Row(
                    children: [
                      Text(
                        lang.cards,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = addresses[index];
              final isSelected = selectedItem == item;

              return SelectableAddressCard(
                title: item.title,
                address: item.address,
                isDefault: item.isDefault,
                isSelected: isSelected,
                icon: "assets/images/Vector.svg",
                onTap: () => setState(() => selectedItem = item),
              );
            }, childCount: addresses.length),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  CustomButton(
                    text: lang.addNewCard,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCardScreen(),
                        ),
                      );
                    },
                    backgroundColor: colorScheme.primary,
                    textColor: colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: lang.apply,
                    onPressed: () {},
                    backgroundColor: theme.cardColor,
                    textColor: colorScheme.primary,
                    hasBorder: true,
                    borderColor: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
