import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/auth/bloc/login_cubit/auth_cubit.dart';
import 'package:mongez/features/auth/screens/register_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/services/navigation_service.dart';
import 'package:mongez/widgets/custom_button.dart';
import 'package:mongez/widgets/custom_text_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          NavigationService.toMainScreen(context, state.auth);
        } else if (state is LoginFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: cs.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    _BrandMark(),
                    const SizedBox(height: 36),
                    Text(
                      lang.login,
                      style: tt.displayMedium?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lang.dontHaveAccount,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomFormField(
                      controller: usernameController,
                      hintText: lang.email,
                      keyboardType: TextInputType.text,
                      preIcon: Icon(Icons.person_outline_rounded,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return lang.pleaseEnterYourEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomFormField(
                      controller: passwordController,
                      hintText: lang.password,
                      obscureText: _obscurePassword,
                      preIcon: Icon(Icons.lock_outline_rounded,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                      sufIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return lang.pleaseEnterYourPassword;
                        }
                        if (v.length < 6) return lang.passwordTooShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    state is LoginLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            text: lang.login,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<LoginCubit>().login(
                                      userName:
                                          usernameController.text.trim(),
                                      password:
                                          passwordController.text.trim(),
                                    );
                              }
                            },
                            backgroundColor: cs.primary,
                            textColor: cs.onPrimary,
                          ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${lang.dontHaveAccount} ',
                          style: tt.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            lang.signUp,
                            style: tt.titleMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/logo.jpg',
              width: 84,
              height: 84,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Mongez',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'منجز',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
        ),
      ],
    );
  }
}
