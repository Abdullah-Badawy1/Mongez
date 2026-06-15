import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/orders/presentation/cubit/customer_orders_cubit.dart';
import 'package:mongez/features/orders/presentation/screens/order_details_screen.dart';
import 'package:mongez/features/orders/presentation/widgets/order_card.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';

class RequistesScreen extends StatefulWidget {
  const RequistesScreen({super.key});

  @override
  State<RequistesScreen> createState() => _RequistesScreenState();
}

class _RequistesScreenState extends State<RequistesScreen> {
  // Cached cubit reference so dispose() doesn't have to touch `context`
  // (which can be torn down in a logout/back-pop race and used to crash).
  CustomerOrdersCubit? _cubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cubit ??= context.read<CustomerOrdersCubit>();
    // Start a 30 s background poll so a dashboard or worker status flip
    // shows up here without a manual pull-to-refresh.
    _cubit!.startPolling();
  }

  @override
  void dispose() {
    _cubit?.stopPolling();
    _cubit = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: lang.myRequests),
      body: BlocBuilder<CustomerOrdersCubit, CustomerOrdersState>(
        builder: (context, state) {
          if (state is CustomerOrdersInitial || state is CustomerOrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CustomerOrdersEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(lang.noRequests),
                ],
              ),
            );
          }
          if (state is CustomerOrdersFailure) {
            return Center(child: Text(state.errorMessage));
          }
          if (state is CustomerOrdersSuccess) {
            final orders = state.orders;
            return RefreshIndicator(
              onRefresh: () => context.read<CustomerOrdersCubit>().getOrders(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return OrderCard(
                    order: order,
                    isCustomer: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(
                            order: order,
                            isCustomer: true,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
