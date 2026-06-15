import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/auth/models/governorate.dart';
import 'package:mongez/features/auth/repos/governorates_repo.dart';
import 'package:mongez/features/profile/data/models/profile_model.dart';
import 'package:mongez/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/services/services_locator.dart';
import 'package:mongez/widgets/custom_app_bar.dart';

/// Real edit-profile screen, wired to PATCH /api/users/me/.
///
/// Loads the current profile from the [ProfileCubit] (which is already
/// kicked off at app boot) and hands the user a single form covering
/// every editable field the backend accepts:
///   • display name (name_ar)
///   • username (login handle — locked here, change via auth flow)
///   • phone / email
///   • governorate (dropdown over /api/governorates/)
///   • city / area
///   • street address (free text)
///
/// On submit it calls `ProfileCubit.updateProfile(...)`; success
/// pops back with a green snackbar, failure shows the backend error
/// inline so the user can fix it.
class EditProfileScreen extends StatefulWidget {
  final ProfileModel profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _addressCtrl;

  Governorate? _selectedGov;
  late Future<List<Governorate>> _govsFuture;

  // Captured in didChangeDependencies so dispose() doesn't have to
  // touch `context` (back-pop crash defense).
  ProfileCubit? _profileCubit;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.nameAr ?? '');
    _phoneCtrl = TextEditingController(text: widget.profile.phone);
    _emailCtrl = TextEditingController(text: '');
    _cityCtrl = TextEditingController(text: widget.profile.city ?? '');
    _addressCtrl = TextEditingController(text: widget.profile.address);
    _govsFuture = _loadGovs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileCubit ??= context.read<ProfileCubit>();
  }

  Future<List<Governorate>> _loadGovs() async {
    final result = await getIt<GovernoratesRepo>().getGovernorates();
    final list = result.fold<List<Governorate>>(
      (_) => <Governorate>[],
      (l) => l,
    );
    // Pre-select the user's current governorate so the form is "ready".
    final currentCode = widget.profile.governorate;
    if (currentCode != null) {
      try {
        _selectedGov = list.firstWhere((g) => g.code == currentCode);
      } catch (_) {
        _selectedGov = null;
      }
    }
    return list;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = _profileCubit;
    if (cubit == null) return;
    cubit.updateProfile(
      nameAr: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      governorate: _selectedGov?.code,
      city: _cityCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (ctx, state) {
        if (state is ProfileSuccess) {
          if (!mounted) return;
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Profile updated'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(ctx).pop();
        } else if (state is ProfileFailure) {
          if (!mounted) return;
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: cs.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (ctx, state) {
        final loading = state is ProfileLoading;
        return Scaffold(
          appBar: const CustomAppBar(title: 'Edit profile'),
          body: AbsorbPointer(
            absorbing: loading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Personal', style: tt.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        hintText: 'e.g. Ahmed Hassan',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Please enter your name'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Please enter your phone';
                        if (s.length < 10) return 'Phone too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text('Address', style: tt.titleSmall),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Governorate>>(
                      future: _govsFuture,
                      builder: (ctx, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: LinearProgressIndicator(),
                          );
                        }
                        final govs = snap.data ?? <Governorate>[];
                        return DropdownButtonFormField<Governorate>(
                          initialValue: _selectedGov,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Governorate / المحافظة',
                            prefixIcon: Icon(Icons.map_outlined),
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
                          onChanged: (g) {
                            if (!mounted) return;
                            setState(() => _selectedGov = g);
                          },
                          validator: (g) =>
                              g == null ? 'Please pick your governorate' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City / Area',
                        hintText: 'e.g. Nasr City',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Street address (optional)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),

                    FilledButton.icon(
                      onPressed: loading ? null : _onSubmit,
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(loading ? 'Saving…' : 'Save changes'),
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
