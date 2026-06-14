import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/orders/presentation/cubit/technician_orders_cubit.dart';
import 'package:mongez/features/orders/presentation/screens/order_details_screen.dart';
import 'package:mongez/features/orders/presentation/widgets/order_card.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: lang.requests),
      body: BlocBuilder<TechnicianOrdersCubit, TechnicianOrdersState>(
        builder: (context, state) {
          if (state is TechnicianOrdersInitial || state is TechnicianOrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TechnicianOrdersEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(lang.noPendingRequests),
                ],
              ),
            );
          }
          if (state is TechnicianOrdersFailure) {
            return Center(child: Text(state.errorMessage));
          }
          if (state is TechnicianOrdersSuccess) {
            final orders = state.orders;
            return RefreshIndicator(
              onRefresh: () => context.read<TechnicianOrdersCubit>().getOrders(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return OrderCard(
                    order: order,
                    isCustomer: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(
                            order: order,
                            isCustomer: false,
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
