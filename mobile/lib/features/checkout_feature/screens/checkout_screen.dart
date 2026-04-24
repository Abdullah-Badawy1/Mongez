import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mongez/core/bloc/orders/orders_cubit.dart';
import 'package:mongez/core/bloc/orders/orders_state.dart';
import 'package:mongez/features/checkout_feature/screens/addresses_screen.dart';
import 'package:mongez/features/checkout_feature/screens/cards_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';
import 'package:mongez/widgets/custom_button.dart';
import 'package:mongez/widgets/custom_text_form_field.dart';

class CheckoutScreen extends StatefulWidget {
  final int? workerId;
  final int? categoryId;

  const CheckoutScreen({super.key, this.workerId, this.categoryId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrdersCubit(),
      child: _CheckoutBody(workerId: widget.workerId, categoryId: widget.categoryId),
    );
  }
}

class _CheckoutBody extends StatefulWidget {
  final int? workerId;
  final int? categoryId;
  const _CheckoutBody({this.workerId, this.categoryId});

  @override
  State<_CheckoutBody> createState() => _CheckoutBodyState();
}

class _CheckoutBodyState extends State<_CheckoutBody> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocListener<OrdersCubit, OrdersState>(
      listener: (context, state) {
        if (state is OrderActionSuccess) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => Dialog(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
                    const SizedBox(height: 16),
                    Text(lang.orderPlaced, style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text(lang.orderSuccess),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: lang.ok,
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (state is OrdersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: colorScheme.error),
          );
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(title: lang.checkout),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(),

                  /// عنوان التوصيل
                  Row(
                    children: [
                      Text(
                        lang.deliveryAddress,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SavedAddressPage(),
                            ),
                          );
                        },
                        child: Text(lang.change),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 8),
                      Text(lang.home),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text("القاهرة - مصر", style: textTheme.bodySmall),
                  ),

                  const SizedBox(height: 12),
                  Divider(),

                  /// الدفع
                  const SizedBox(height: 12),
                  Text(
                    lang.paymentMethod,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _PaymentMethodItem(
                        icon: Icons.credit_card,
                        title: lang.card,
                        isSelected: selectedIndex == 0,
                        onTap: () => setState(() => selectedIndex = 0),
                      ),
                      const SizedBox(width: 10),
                      _PaymentMethodItem(
                        icon: Icons.money,
                        title: lang.cash,
                        isSelected: selectedIndex == 1,
                        onTap: () => setState(() => selectedIndex = 1),
                      ),
                      const SizedBox(width: 10),
                      _PaymentMethodItem(
                        icon: Icons.apple,
                        title: lang.applePay,
                        isSelected: selectedIndex == 2,
                        onTap: () => setState(() => selectedIndex = 2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CardsScreen()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      height: 50,
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          SvgPicture.asset(
                            'assets/images/Vector.svg',
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          const Text("**** **** **** 1234"),
                          const Spacer(),
                          Icon(Icons.keyboard_arrow_down),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Divider(),

                  const SizedBox(height: 12),

                  Text(lang.description, style: textTheme.titleMedium),

                  const SizedBox(height: 12),

                  CustomFormField(hintText: lang.enterProblem),

                  const SizedBox(height: 12),
                  Divider(),

                  const SizedBox(height: 12),

                  Text(lang.bookingFee, style: textTheme.titleMedium),

                  _OrderItemRow(
                    name: lang.price,
                    price: "50 جنيه",
                    isBold: true,
                  ),

                  const SizedBox(height: 12),

                  Text(lang.note, style: TextStyle(color: colorScheme.error)),

                  const SizedBox(height: 12),

                  Divider(),
                  const SizedBox(height: 12),

                  Text(lang.promoCode, style: textTheme.titleMedium),

                  Row(
                    children: [
                      Expanded(
                        child: CustomFormField(hintText: lang.enterPromo),
                      ),
                      const SizedBox(width: 12),
                      CustomButton(
                        text: lang.apply,
                        onPressed: () {},
                        width: 100,
                        height: 50,
                        backgroundColor: colorScheme.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  BlocBuilder<OrdersCubit, OrdersState>(
                    builder: (context, state) {
                      final isLoading = state is OrdersLoading;
                      return CustomButton(
                        text: isLoading ? '...' : lang.placeOrder,
                        onPressed: isLoading || widget.categoryId == null
                            ? null
                            : () => context.read<OrdersCubit>().createOrder(
                                  categoryId: widget.categoryId!,
                                  workerId: widget.workerId,
                                ),
                        backgroundColor: colorScheme.primary,
                        height: 50,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ====================== Payment Item ======================
class _PaymentMethodItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bgColor = isSelected ? colorScheme.primary : theme.cardColor;

    final borderColor = isSelected ? colorScheme.primary : Colors.grey.shade300;

    final contentColor = isSelected
        ? colorScheme.onPrimary
        : textTheme.bodyMedium?.color;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: contentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: contentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ====================== Order Item Row ======================
class _OrderItemRow extends StatelessWidget {
  final String name;
  final String price;
  final bool isBold;

  const _OrderItemRow({
    required this.name,
    required this.price,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            name,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            price,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
