import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:task_flow/features/projects/presentation/screens/project_list_screen.dart';
import 'package:task_flow/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:task_flow/features/profile/presentation/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ProjectListScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.5),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder_rounded),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                final count = context.read<NotificationCubit>().unreadCount;
                if (count > 0) {
                  return Badge(
                    label: Text('$count'),
                    child: const Icon(Icons.notifications_outlined),
                  );
                }
                return const Icon(Icons.notifications_outlined);
              },
            ),
            activeIcon: BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                final count = context.read<NotificationCubit>().unreadCount;
                if (count > 0) {
                  return Badge(
                    label: Text('$count'),
                    child: const Icon(Icons.notifications_rounded),
                  );
                }
                return const Icon(Icons.notifications_rounded);
              },
            ),
            label: 'Inbox',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton(
              onPressed: () => context.push(AppConstants.routeSettings),
              tooltip: 'Settings',
              child: const Icon(Icons.settings_rounded),
            )
          : null,
    );
  }
}
