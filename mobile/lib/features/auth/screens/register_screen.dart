import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/account/screens/add_service_screen.dart';
import 'package:mongez/features/auth/bloc/register_cubit/register_cubit.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/services/navigation_service.dart';
import 'package:mongez/widgets/custom_button.dart';
import 'package:mongez/widgets/custom_text_form_field.dart';
import 'package:mongez/widgets/logo.dart';
import 'package:mongez/widgets/profile_image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String _selectedRole = 'client';

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocConsumer<RegisterCubit, RegisterState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          final isWorker = state.auth.user?.role == 'worker';
          if (isWorker) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AddServiceScreen(pendingAuth: state.auth),
              ),
            );
          } else {
            NavigationService.toMainScreen(context, state.auth);
          }
        } else if (state is RegisterFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<RegisterCubit>();
        final isImageLoading = state is RegisterImageLoading;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Logo(),
                    const SizedBox(height: 32),

                    ProfileImagePicker(
                      imageBytes: state.imageBytes,
                      isImageLoading: isImageLoading,
                      onImagePicked: (file) => cubit.setImage(file),
                    ),

                    const SizedBox(height: 24),

                    /// Role Toggle
                    Row(
                      children: [
                        Expanded(
                          child: _RoleButton(
                            label: lang.customer,
                            selected: _selectedRole == 'client',
                            onTap: () => setState(() => _selectedRole = 'client'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _RoleButton(
                            label: lang.technician,
                            selected: _selectedRole == 'worker',
                            onTap: () => setState(() => _selectedRole = 'worker'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// Username Field
                    CustomFormField(
                      controller: nameController,
                      hintText: lang.fullName,
                      preIcon: Icon(
                        Icons.person,
                        color: textTheme.bodySmall?.color,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return lang.pleaseEnterYourName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    /// Phone Field
                    CustomFormField(
                      controller: phoneController,
                      hintText: lang.phoneNumber,
                      keyboardType: TextInputType.phone,
                      preIcon: Icon(
                        Icons.phone,
                        color: textTheme.bodySmall?.color,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return lang.pleaseEnterYourPhoneNumber;
                        }
                        if (value.length < 10) {
                          return lang.invalidPhoneNumber;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    /// Address Field
                    CustomFormField(
                      controller: addressController,
                      hintText: lang.address,
                      preIcon: Icon(
                        Icons.location_on,
                        color: textTheme.bodySmall?.color,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return lang.pleaseEnterYourPhoneNumber;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    /// Password Field
                    CustomFormField(
                      controller: passwordController,
                      hintText: lang.password,
                      obscureText: true,
                      preIcon: Icon(
                        Icons.lock,
                        color: textTheme.bodySmall?.color,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return lang.pleaseEnterYourPassword;
                        }
                        if (value.length < 6) {
                          return lang.passwordTooShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    /// Register Button
                    state is RegisterLoading
                        ? const CircularProgressIndicator()
                        : CustomButton(
                            text: lang.register,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                cubit.register(
                                  userName: nameController.text.trim(),
                                  password: passwordController.text.trim(),
                                  address: addressController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  role: _selectedRole,
                                );
                              }
                            },
                            backgroundColor: colorScheme.primary,
                            textColor: colorScheme.onPrimary,
                          ),
                    const SizedBox(height: 20),

                    /// Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${lang.alreadyHaveAccount} ',
                          style: textTheme.bodyMedium?.copyWith(fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            lang.login,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary,
            width: selected ? 0 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selected ? colorScheme.onPrimary : colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}


