import 'package:flutter/material.dart';
import 'package:mongez/core/app_colors.dart';
import 'package:mongez/features/checkout_feature/components/molecules/address.dart';
import 'package:mongez/features/checkout_feature/screens/add_address_screen.dart';
import 'package:mongez/widgets/custom_app_bar.dart';
import 'package:mongez/widgets/custom_button.dart';

class SavedAddressPage extends StatefulWidget {
  const SavedAddressPage({super.key});

  @override
  State<SavedAddressPage> createState() => _SavedAddressPageState();
}

class _SavedAddressPageState extends State<SavedAddressPage> {
  final List<AddressModel> addresses = [
    AddressModel(
      title: "Home",
      address: "925 S Chugach St #APT 10, Alas...",
      isDefault: true,
    ),
    AddressModel(
      title: "Office",
      address: "2438 6th Ave, Ketchikan, Alaska 99...",
    ),
    AddressModel(
      title: "Apartment",
      address: "2551 Vista Dr #B301, Juneau, Alask...",
    ),
    AddressModel(
      title: "Parent's House",
      address: "4821 Ridge Top Cir, Anchorage, Ala...",
    ),
  ];

  String selectedAddress = "Home";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "My Addresses"),
      body: CustomScrollView(
        slivers: [
          // 🔹 Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Divider(thickness: 1, color: AppColors.gray3),
                  Row(
                    children: const [
                      Text(
                        "Delivery Address",
                        style: TextStyle(
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

          // 🔹 Addresses List
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = addresses[index];
              final bool isSelected = selectedAddress == item.title;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SelectableCard(
                  title: item.title, // nullable
                  subtitle: item.address,
                  isDefault: item.isDefault,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      selectedAddress = item.title ?? '';
                    });
                  },
                ),
              );
            }, childCount: addresses.length),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  CustomButton(
                    text: 'Add New Address',
                    onPressed: () {
                      // Navigate to Add Address Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddAddressScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  CustomButton(
                    text: "Apply",
                    onPressed: () {},
                    backgroundColor: AppColors.white,
                    textColor: AppColors.primary,
                    hasBorder: true,
                    borderColor: AppColors.primary,
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

// 📦 Address Model
class AddressModel {
  final String? title; // 👈 nullable
  final String address;
  final bool isDefault;

  AddressModel({this.title, required this.address, this.isDefault = false});
}
