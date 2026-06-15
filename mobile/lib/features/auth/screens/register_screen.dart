import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/account/screens/add_service_screen.dart';
import 'package:mongez/features/auth/bloc/register_cubit/register_cubit.dart';
import 'package:mongez/features/auth/models/governorate.dart';
import 'package:mongez/features/auth/repos/governorates_repo.dart';
import 'package:mongez/features/home/bloc/categories_cubit/categories_cubit.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/services/navigation_service.dart';
import 'package:mongez/services/services_locator.dart';
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
  // Full display name — any unicode, can have spaces. Goes to the backend
  // as `name_ar` (which the User model treats as the display name).
  final TextEditingController nameController = TextEditingController();
  // Login handle — Django's UnicodeUsernameValidator only allows
  // letters / digits / `@.+-_`, no spaces. Kept separate from the
  // display name so users can pick the friendly form for both.
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  // City / area — free text (e.g. "Nasr City", "Maadi") on top of the
  // structured governorate dropdown below.
  final TextEditingController cityController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String _selectedRole = 'client';
  Governorate? _selectedGovernorate;

  // Cached on the page so a rebuild from setState doesn't re-hit
  // /api/governorates/ — the repo also caches but this skips even the
  // Either-unwrap.
  late Future<List<Governorate>> _governoratesFuture;

  static final RegExp _usernameRegex = RegExp(r'^[A-Za-z0-9_.@+\-]+$');

  @override
  void initState() {
    super.initState();
    _governoratesFuture = _loadGovernorates();
    // Pre-warm the categories list. By the time a freshly-registered
    // worker hits AddServiceScreen the categories are already cached
    // in the repo and the dropdown shows up instantly.
    // didChangeDependencies is the right place to touch context, but
    // we just need to schedule the fetch — the cubit will absorb the
    // call safely even if it runs twice.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoriesCubit>().fetchCategories();
    });
  }

  Future<List<Governorate>> _loadGovernorates() async {
    final result = await getIt<GovernoratesRepo>().getGovernorates();
    return result.fold(
      (failure) => throw Exception(failure.errorMessage),
      (list) => list,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    cityController.dispose();
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

                    /// Full Name field — display name (spaces / Arabic OK)
                    CustomFormField(
                      controller: nameController,
                      hintText: lang.fullName,
                      preIcon: Icon(
                        Icons.person,
                        color: textTheme.bodySmall?.color,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return lang.pleaseEnterYourName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    /// Username field — login handle, no spaces.
                    CustomFormField(
                      controller: usernameController,
                      hintText: 'Username (no spaces)',
                      preIcon: Icon(
                        Icons.alternate_email,
                        color: textTheme.bodySmall?.color,
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) {
                          return 'Please enter a username';
                        }
                        if (v.contains(' ')) {
                          return 'Username cannot contain spaces';
                        }
                        if (!_usernameRegex.hasMatch(v)) {
                          return 'Use letters, numbers, or _ . + - @';
                        }
                        if (v.length < 3) {
                          return 'Username is too short';
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

                    /// Governorate dropdown — required. Hydrated from
                    /// the backend /api/governorates/ so the list stays
                    /// in one place. Shows the Arabic name with English
                    /// in subtitle for the typical bilingual user.
                    FutureBuilder<List<Governorate>>(
                      future: _governoratesFuture,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: LinearProgressIndicator(),
                          );
                        }
                        if (snap.hasError) {
                          return InkWell(
                            onTap: () {
                              if (!mounted) return;
                              setState(() {
                                _governoratesFuture = _loadGovernorates();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.refresh, color: colorScheme.error),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Couldn't load governorates — tap to retry",
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final govs = snap.data ?? const <Governorate>[];
                        return DropdownButtonFormField<Governorate>(
                          initialValue: _selectedGovernorate,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Governorate / المحافظة',
                            prefixIcon: Icon(
                              Icons.map_outlined,
                              color: textTheme.bodySmall?.color,
                            ),
                          ),
                          items: govs
                              .map(
                                (g) => DropdownMenuItem<Governorate>(
                                  value: g,
                                  child: Text(
                                    '${g.nameAr} · ${g.nameEn}',
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (g) => setState(() => _selectedGovernorate = g),
                          validator: (g) => g == null
                              ? 'Please pick your governorate'
                              : null,
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    /// City / Area — free text (e.g. "Nasr City", "Maadi").
                    /// Optional, but most users fill it.
                    CustomFormField(
                      controller: cityController,
                      hintText: 'City / Area (optional)',
                      preIcon: Icon(
                        Icons.location_city_outlined,
                        color: textTheme.bodySmall?.color,
                      ),
                      validator: (_) => null,
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
                              if (_formKey.currentState!.validate() &&
                                  _selectedGovernorate != null) {
                                cubit.register(
                                  userName: usernameController.text.trim(),
                                  name: nameController.text.trim(),
                                  password: passwordController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  role: _selectedRole,
                                  governorate: _selectedGovernorate!.code,
                                  city: cityController.text.trim(),
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


