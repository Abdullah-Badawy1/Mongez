import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/app_colors.dart';
import 'package:mongez/features/checkout/widgets/attachments_picker.dart';
import 'package:mongez/features/orders/presentation/cubit/checkout_cubit.dart';
import 'package:mongez/features/orders/presentation/cubit/customer_orders_cubit.dart';
import 'package:mongez/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/features/workers/data/models/worker_model.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';
import 'package:mongez/widgets/custom_button.dart';
import 'package:mongez/widgets/custom_text_form_field.dart';

class CheckoutScreen extends StatefulWidget {
  final WorkerModel worker;
  const CheckoutScreen({super.key, required this.worker});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _useAccountPhone = true;
  bool _useSavedAddress = true;
  bool _initialized = false;
  String _urgency = 'NORMAL';
  AttachmentBundle _attachments = const AttachmentBundle();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadDefaults();
    }
  }

  void _loadDefaults() {
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is ProfileSuccess) {
      if (_phoneController.text.isEmpty) {
        _phoneController.text = profileState.profile.phone;
      }
      if (_addressController.text.isEmpty) {
        _addressController.text = profileState.profile.address;
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) return;

    context.read<CheckoutCubit>().createOrder(
      serviceCategory: widget.worker.categoryId ?? 0,
      workerId: widget.worker.userId ?? widget.worker.id,
      description: _descriptionController.text.trim(),
      address: _useSavedAddress ? null : _addressController.text.trim(),
      phone: _useAccountPhone ? null : _phoneController.text.trim(),
      urgency: _urgency,
      photoPaths: _attachments.photoPaths,
      audioPath: _attachments.audioPath,
      audioDurationSeconds: _attachments.audioDurationSeconds,
    );
  }

  String? _validateRequired(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'This field is required';
    return null;
  }

  String? _validatePhone(String? value) {
    if (_useAccountPhone) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > 20) return 'Phone number is too long';
    if (!RegExp(r'^\+?[\d\s\-()]{7,20}$').hasMatch(text)) {
      return 'Invalid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state is CheckoutFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage)),
          );
        }
        if (state is CheckoutSuccess) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 60),
                    const SizedBox(height: 16),
                    Text(lang.orderPlaced, style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text(lang.orderSuccess),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: lang.ok,
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        context.read<CustomerOrdersCubit>().getOrders();
                        Navigator.pop(context);
                        navigator.popUntil((route) => route.isFirst);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(title: lang.checkout),
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildWorkerCard(theme, textTheme)),
              SliverToBoxAdapter(
                  child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                  child: _buildSection(
                theme: theme,
                textTheme: textTheme,
                lang: lang,
                title: lang.orderDetails,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomFormField(
                      controller: _descriptionController,
                      hintText: lang.enterProblem,
                      keyboardType: TextInputType.multiline,
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Add photos or a voice note to explain the issue',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AttachmentsPicker(
                      onChanged: (b) => _attachments = b,
                    ),
                  ],
                ),
              )),
              SliverToBoxAdapter(
                  child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                  child: _buildSection(
                theme: theme,
                textTheme: textTheme,
                lang: lang,
                title: 'Urgency',
                child: _UrgencyPicker(
                  value: _urgency,
                  onChanged: (v) => setState(() => _urgency = v),
                ),
              )),
              SliverToBoxAdapter(
                  child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                  child: _buildSection(
                theme: theme,
                textTheme: textTheme,
                lang: lang,
                title: lang.contactInfo,
                child: _buildPhoneField(theme, textTheme, lang),
              )),
              SliverToBoxAdapter(
                  child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                  child: _buildSection(
                theme: theme,
                textTheme: textTheme,
                lang: lang,
                title: lang.deliveryAddress,
                child: _buildAddressField(theme, textTheme, lang),
              )),
              SliverToBoxAdapter(
                  child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                  child: Text(lang.note,
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant))),
              SliverToBoxAdapter(
                  child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                  child: BlocBuilder<CheckoutCubit, CheckoutState>(
                builder: (context, state) {
                  final isLoading = state is CheckoutLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              lang.placeOrder,
                              style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  );
                },
              )),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerCard(ThemeData theme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: ClipOval(
              child: widget.worker.profileImage != null
                  ? Image.network(
                      widget.worker.profileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person),
                    )
                  : const Icon(Icons.person),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.worker.username ?? '',
                  style: textTheme.titleMedium),
              Text(widget.worker.categoryName ?? '',
                  style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required ThemeData theme,
    required TextTheme textTheme,
    required S lang,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text.isEmpty ? 'Not set' : text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: text.isEmpty
                    ? theme.textTheme.bodySmall?.color
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(
      ThemeData theme, TextTheme textTheme, S lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggleRow(
          label: lang.useAccountPhone,
          value: _useAccountPhone,
          onChanged: (value) {
            setState(() {
              _useAccountPhone = value;
              if (value) {
                final profileState =
                    context.read<ProfileCubit>().state;
                if (profileState is ProfileSuccess) {
                  _phoneController.text =
                      profileState.profile.phone;
                }
              }
            });
          },
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _useAccountPhone
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _buildReadOnlyField(
              Icons.phone_outlined, _phoneController.text),
          secondChild: CustomFormField(
            controller: _phoneController,
            hintText: lang.phoneForOrder,
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressField(
      ThemeData theme, TextTheme textTheme, S lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggleRow(
          label: lang.useSavedAddress,
          value: _useSavedAddress,
          onChanged: (value) {
            setState(() {
              _useSavedAddress = value;
              if (value) {
                final profileState =
                    context.read<ProfileCubit>().state;
                if (profileState is ProfileSuccess) {
                  _addressController.text =
                      profileState.profile.address;
                }
              }
            });
          },
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _useSavedAddress
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _buildReadOnlyField(
              Icons.location_on_outlined, _addressController.text),
          secondChild: CustomFormField(
            controller: _addressController,
            hintText: lang.addressForOrder,
            keyboardType: TextInputType.streetAddress,
          ),
        ),
      ],
    );
  }
}

class _UrgencyPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _UrgencyPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final options = <Map<String, dynamic>>[
      {'key': 'LOW', 'label': 'Whenever', 'icon': Icons.schedule, 'color': AppColors.success},
      {'key': 'NORMAL', 'label': 'Today', 'icon': Icons.today_outlined, 'color': AppColors.primary},
      {'key': 'HIGH', 'label': 'Emergency', 'icon': Icons.local_fire_department_outlined, 'color': AppColors.danger},
    ];
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => onChanged(options[i]['key']),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: value == options[i]['key']
                      ? (options[i]['color'] as Color).withValues(alpha: 0.14)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: value == options[i]['key']
                        ? options[i]['color'] as Color
                        : cs.outline.withValues(alpha: 0.4),
                    width: value == options[i]['key'] ? 1.6 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      options[i]['icon'] as IconData,
                      color: options[i]['color'] as Color, size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      options[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: value == options[i]['key']
                            ? options[i]['color'] as Color
                            : cs.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
