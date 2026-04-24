import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> elements;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.elements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BottomNavigationBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: textTheme.bodySmall?.color,
      selectedLabelStyle: textTheme.bodySmall?.copyWith(fontSize: 12),
      unselectedLabelStyle: textTheme.bodySmall?.copyWith(fontSize: 12),
      currentIndex: currentIndex,
      onTap: onTap,
      items: elements.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        final isSelected = currentIndex == index;

        return BottomNavigationBarItem(
          icon: Image.asset(
            item.iconPath,
            width: 24,
            height: 24,
            color: isSelected
                ? colorScheme.primary
                : textTheme.bodySmall?.color,
          ),
          label: item.label,
        );
      }).toList(),
    );
  }
}

class NavItem {
  final String label;
  final String iconPath;

  const NavItem({required this.label, required this.iconPath});
}
