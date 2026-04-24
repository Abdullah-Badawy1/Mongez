import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/bloc/auth/auth_cubit.dart';
import 'package:mongez/core/bloc/auth/auth_state.dart';
import 'package:mongez/features/login_feature/screens/register_screen.dart';
import 'package:mongez/features/main_screen/main_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_button.dart';
import 'package:mongez/widgets/custom_text_form_field.dart';
import 'package:mongez/widgets/logo.dart';

class LoginScreen extends StatelessWidget {
  final bool isCustomer;
  const LoginScreen({super.key, required this.isCustomer});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(),
      child: _LoginBody(isCustomer: isCustomer),
    );
  }
}

class _LoginBody extends StatefulWidget {
  final bool isCustomer;
  const _LoginBody({required this.isCustomer});

  @override
  State<_LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
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
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),
                  const Logo(),
                  const SizedBox(height: 170),

                  CustomFormField(
                    controller: _usernameController,
                    hintText: lang.username,
                    keyboardType: TextInputType.text,
                    preIcon: Icon(
                      Icons.person,
                      color: textTheme.bodySmall?.color,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return lang.pleaseEnterYourUsername;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  CustomFormField(
                    controller: _passwordController,
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
                  const SizedBox(height: 40),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return CustomButton(
                        text: state is AuthLoading ? '...' : lang.login,
                        onPressed: state is AuthLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<AuthCubit>().login(
                                        username:
                                            _usernameController.text.trim(),
                                        password: _passwordController.text,
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
                        '${lang.dontHaveAccount} ',
                        style: textTheme.bodyMedium?.copyWith(fontSize: 16),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(
                                isCustomer: widget.isCustomer,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          lang.signUp,
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
