import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/bloc/auth/auth_cubit.dart';
import 'package:mongez/core/bloc/auth/auth_state.dart';
import 'package:mongez/features/main_screen/main_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_button.dart';
import 'package:mongez/widgets/custom_text_form_field.dart';
import 'package:mongez/widgets/logo.dart';

class RegisterScreen extends StatelessWidget {
  final bool isCustomer;
  const RegisterScreen({super.key, required this.isCustomer});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(),
      child: _RegisterBody(isCustomer: isCustomer),
    );
  }
}

class _RegisterBody extends StatefulWidget {
  final bool isCustomer;
  const _RegisterBody({required this.isCustomer});

  @override
  State<_RegisterBody> createState() => _RegisterBodyState();
}

class _RegisterBodyState extends State<_RegisterBody> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainScreen(isCustomer: state.user.isClient),
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
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
                  const SizedBox(height: 80),

                  CustomFormField(
                    controller: _usernameController,
                    hintText: lang.username,
                    preIcon:
                        Icon(Icons.person, color: textTheme.bodySmall?.color),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return lang.pleaseEnterYourUsername;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  CustomFormField(
                    controller: _phoneController,
                    hintText: lang.phoneNumber,
                    keyboardType: TextInputType.phone,
                    preIcon:
                        Icon(Icons.phone, color: textTheme.bodySmall?.color),
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

                  CustomFormField(
                    controller: _addressController,
                    hintText: lang.address,
                    preIcon: Icon(Icons.location_on_outlined,
                        color: textTheme.bodySmall?.color),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return lang.pleaseEnterYourAddress;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  CustomFormField(
                    controller: _passwordController,
                    hintText: lang.password,
                    obscureText: true,
                    preIcon:
                        Icon(Icons.lock, color: textTheme.bodySmall?.color),
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

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return CustomButton(
                        text: state is AuthLoading ? '...' : lang.register,
                        onPressed: state is AuthLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<AuthCubit>().register(
                                        username:
                                            _usernameController.text.trim(),
                                        phone: _phoneController.text.trim(),
                                        address: _addressController.text.trim(),
                                        password: _passwordController.text,
                                        role: widget.isCustomer
                                            ? 'client'
                                            : 'worker',
                                      );
                                }
                              },
                        backgroundColor: colorScheme.primary,
                        textColor: colorScheme.onPrimary,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

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
      ),
    );
  }
}
