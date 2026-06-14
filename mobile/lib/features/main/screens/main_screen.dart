import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/account/screens/account_screen.dart';
import 'package:mongez/features/favorites/screens/favorite_screen.dart';
import 'package:mongez/features/home/screens/home_screen.dart';
import 'package:mongez/features/auth/models/auth.dart';
import 'package:mongez/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mongez/features/requests/screens/customer_requests_screen.dart';
import 'package:mongez/features/job_history/screens/job_history_screen.dart';
import 'package:mongez/features/requests/screens/technician_requests_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  final Auth auth;
  const MainScreen({super.key, required this.auth});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  NotificationCubit? _notifCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifCubit = context.read<NotificationCubit>();
      _notifCubit?.startPolling();
    });
  }

  @override
  void dispose() {
    // Use the saved reference — context.read after deactivate throws.
    _notifCubit?.stopPolling();
    super.dispose();
  }

  late final List<Widget> _screensCustomer = [
    HomeScreen(isCustomer: true, user: widget.auth.user!),
    FavoiriteScreen(),
    const RequistesScreen(),
    const AccountScreen(isCustomer: true),
  ];

  late final List<Widget> _screensTechnician = [
    HomeScreen(isCustomer: false, user: widget.auth.user!),
    const JobHistoryScreen(),
    const RequestsScreen(),
    const AccountScreen(isCustomer: false),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final isCustomer = widget.auth.user!.role == 'client';

    return Scaffold(
      body: isCustomer
          ? _screensCustomer[_currentIndex]
          : _screensTechnician[_currentIndex],
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        elements: [
          NavItem(label: lang.home, iconPath: 'assets/images/home icon.png'),
          NavItem(
            label: isCustomer ? lang.favorites : lang.jobHistory,
            iconPath: isCustomer
                ? 'assets/images/saved icon.png'
                : 'assets/images/Wallet-duotone.png',
          ),
          NavItem(
            label: lang.requests,
            iconPath: 'assets/images/shopping-cart.png',
          ),
          NavItem(label: lang.account, iconPath: 'assets/images/user icon.png'),
        ],
      ),
    );
  }
}

