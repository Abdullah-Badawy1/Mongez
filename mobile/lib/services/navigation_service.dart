import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/auth/bloc/login_cubit/auth_cubit.dart';
import 'package:mongez/features/auth/bloc/register_cubit/register_cubit.dart';
import 'package:mongez/features/auth/models/auth.dart';
import 'package:mongez/features/auth/screens/get_started_screen.dart';
import 'package:mongez/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:mongez/features/home/bloc/categories_cubit/categories_cubit.dart';
import 'package:mongez/features/main/screens/main_screen.dart';
import 'package:mongez/features/orders/presentation/cubit/checkout_cubit.dart';
import 'package:mongez/features/orders/presentation/cubit/customer_orders_cubit.dart';
import 'package:mongez/features/orders/presentation/cubit/job_history_cubit.dart';
import 'package:mongez/features/orders/presentation/cubit/technician_orders_cubit.dart';
import 'package:mongez/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/features/workers/presentation/cubit/create_worker_profile_cubit.dart';
import 'package:mongez/features/workers/presentation/cubit/workers_cubit.dart';
import 'package:mongez/services/helper.dart';

class NavigationService {
  static Future<void> toMainScreen(BuildContext context, Auth auth) async {
    _clearImageCache();
    _resetAllCubits(context);
    _fetchFreshData(context);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MainScreen(auth: auth)),
      (route) => false,
    );
  }

  static Future<void> logout(BuildContext context) async {
    _clearImageCache();
    _resetAllCubits(context);
    final navigator = Navigator.of(context);
    await PrefHelper.clearAll();

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GetStartedScreen()),
      (route) => false,
    );
  }

  static void _clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  static void _resetAllCubits(BuildContext context) {
    context.read<ProfileCubit>().reset();
    context.read<FavoritesCubit>().reset();
    context.read<CustomerOrdersCubit>().reset();
    context.read<TechnicianOrdersCubit>().reset();
    context.read<JobHistoryCubit>().reset();
    context.read<WorkersCubit>().reset();
    context.read<CategoriesCubit>().reset();
    context.read<LoginCubit>().reset();
    context.read<RegisterCubit>().reset();
    context.read<CheckoutCubit>().reset();
    context.read<CreateWorkerProfileCubit>().reset();
  }

  static void _fetchFreshData(BuildContext context) {
    context.read<ProfileCubit>().getProfile();
    context.read<FavoritesCubit>().getFavorites();
    context.read<CustomerOrdersCubit>().getOrders();
    context.read<TechnicianOrdersCubit>().getOrders();
    context.read<JobHistoryCubit>().getJobHistory();
    context.read<WorkersCubit>().refresh();
    context.read<CategoriesCubit>().fetchCategories();
  }
}
