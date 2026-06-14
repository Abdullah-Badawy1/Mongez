import 'package:flutter/material.dart';
import 'package:mongez/core/app_colors.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';
import 'package:mongez/widgets/custom_button.dart';
import 'package:mongez/widgets/custom_text_form_field.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  bool isDefault = false;

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: lang.addNewAddress),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Divider(thickness: 1, color: AppColors.gray3),

                  Row(
                    children: [
                      Text(
                        lang.address,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Text(
                        lang.addressNickname,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  CustomFormField(),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Text(
                        lang.addressDetails,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  CustomFormField(),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Checkbox(
                        value: isDefault,
                        onChanged: (bool? value) {
                          setState(() {
                            isDefault = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                        checkColor: Colors.white,
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lang.makeDefault,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  CustomButton(text: lang.apply, onPressed: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
