import 'package:flutter/material.dart';
import 'package:mongez/features/account/screens/account_screen.dart';
import 'package:mongez/features/favoirite/screens/favoirite_screen.dart';
import 'package:mongez/features/home_feature/screens/home_screen.dart';
import 'package:mongez/features/requistes/screens/requistes_screen.dart';
import 'package:mongez/features/t_jop_history/screens/t_jop_history_screen.dart';
import 'package:mongez/features/t_requestes/screens/t_requiests.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  final bool isCustomer;
  const MainScreen({super.key, required this.isCustomer});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screensCustomer = [
    const HomeScreen(isCustomer: true),
    const FavoiriteScreen(),
    const RequistesScreen(),
    const AccountScreen(isCustomer: true),
  ];

  late final List<Widget> _screensTechnician = [
    const HomeScreen(isCustomer: false),
    const JobHistoryScreen(),
    const RequestsScreen(),
    const AccountScreen(isCustomer: false),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);

    return Scaffold(
      body: widget.isCustomer
          ? _screensCustomer[_currentIndex]
          : _screensTechnician[_currentIndex],
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        elements: [
          NavItem(label: lang.home, iconPath: 'assets/images/home icon.png'),
          NavItem(
            label: widget.isCustomer ? lang.favorites : lang.jobHistory,
            iconPath: widget.isCustomer
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
