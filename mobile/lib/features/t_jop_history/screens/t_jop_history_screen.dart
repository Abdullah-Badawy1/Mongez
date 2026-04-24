import 'package:flutter/material.dart';
import 'package:mongez/core/app_colors.dart';
import 'package:mongez/widgets/custom_app_bar.dart';

class JobHistoryScreen extends StatelessWidget {
  const JobHistoryScreen({super.key});

  // داتا تجريبية
  List<JobModel> get jobs => [
    JobModel(
      title: "Electric Fix",
      description: "Fixed power outage in living room",
      status: "completed",
      date: DateTime(2026, 2, 5),
    ),
    JobModel(
      title: "Plumbing Service",
      description: "Repaired kitchen sink leak",
      status: "canceled",
      date: DateTime(2026, 1, 28),
    ),
    JobModel(
      title: "Cleaning Service",
      description: "Full apartment cleaning",
      status: "completed",
      date: DateTime(2026, 2, 1),
    ),
  ];

  Color _statusColor(String status) {
    switch (status) {
      case "completed":
        return AppColors.primary;
      case "canceled":
        return AppColors.danger;
      default:
        return AppColors.gray5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Job History"),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray9,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(job.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          job.status.toUpperCase(),
                          style: TextStyle(
                            color: _statusColor(job.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    job.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray6,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Date Row
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.gray4,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${job.date.day}/${job.date.month}/${job.date.year}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class JobModel {
  final String title;
  final String description;
  final String status; // completed | canceled
  final DateTime date;

  JobModel({
    required this.title,
    required this.description,
    required this.status,
    required this.date,
  });
}
