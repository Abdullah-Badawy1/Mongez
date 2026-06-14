import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mongez/features/notifications/presentation/screens/notification_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double height;
  final bool centerTitle;
  final bool showNotification;

  const CustomAppBar({
    super.key,
    required this.title,
    this.height = kToolbarHeight,
    this.centerTitle = true,
    this.showNotification = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leading: Navigator.canPop(context)
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Material(
                color: cs.surfaceContainerHighest,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    isRtl
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                    size: 20,
                    color: cs.onSurface,
                  ),
                ),
              ),
            )
          : null,
      title: Text(
        title,
        style: tt.headlineSmall?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        if (showNotification)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 14),
            child: BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                final unread =
                    context.watch<NotificationCubit>().unreadCount;
                return Material(
                  color: cs.surfaceContainerHighest,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Badge(
                        isLabelVisible: unread > 0,
                        label: Text('$unread',
                            style: const TextStyle(fontSize: 10)),
                        child: Icon(
                          Icons.notifications_outlined,
                          size: 22,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
