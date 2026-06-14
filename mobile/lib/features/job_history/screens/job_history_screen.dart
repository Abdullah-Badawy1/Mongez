import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/orders/presentation/cubit/job_history_cubit.dart';
import 'package:mongez/features/orders/presentation/screens/order_details_screen.dart';
import 'package:mongez/features/orders/presentation/widgets/order_card.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';

class JobHistoryScreen extends StatelessWidget {
  const JobHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: lang.jobHistory),
      body: BlocBuilder<JobHistoryCubit, JobHistoryState>(
        builder: (context, state) {
          if (state is JobHistoryInitial || state is JobHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is JobHistoryEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(lang.noJobHistory),
                ],
              ),
            );
          }
          if (state is JobHistoryFailure) {
            return Center(child: Text(state.errorMessage));
          }
          if (state is JobHistorySuccess) {
            final jobs = state.jobs;
            return RefreshIndicator(
              onRefresh: () => context.read<JobHistoryCubit>().getJobHistory(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return OrderCard(
                    order: job,
                    isCustomer: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(
                            order: job,
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
