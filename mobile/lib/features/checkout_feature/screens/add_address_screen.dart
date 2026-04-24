import 'package:flutter/material.dart';
import 'package:mongez/core/app_colors.dart';
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
    return Scaffold(
      appBar: CustomAppBar(title: 'Add New Address'),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Divider(thickness: 1, color: AppColors.gray3),

                  Row(
                    children: const [
                      Text(
                        "Address",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  Row(
                    children: const [
                      Text(
                        "Address Nickname",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  CustomFormField(),

                  SizedBox(height: 30),

                  Row(
                    children: const [
                      Text(
                        "Address Detailes",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  CustomFormField(),

                  SizedBox(height: 12),

                  Row(
                    children: [
                      Checkbox(
                        value: isDefault,
                        onChanged: (bool? value) {
                          setState(() {
                            isDefault = value ?? false;
                          });
                        },
                        activeColor:
                            AppColors.primary, // لون المربع لما يكون Checked
                        checkColor: Colors.white, // لون علامة الصح ✔
                        side: const BorderSide(
                          color: AppColors.primary, // لون الإطار
                          width: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Make this as a default",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  CustomButton(text: "Apply", onPressed: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
