import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';
import 'package:task_flow/features/auth/presentation/screens/login_screen.dart';
import 'package:task_flow/features/auth/presentation/screens/register_screen.dart';
import 'package:task_flow/features/auth/presentation/screens/splash_screen.dart';
import 'package:task_flow/features/home/presentation/screens/home_screen.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:task_flow/features/projects/presentation/screens/project_detail_screen.dart';
import 'package:task_flow/features/projects/presentation/screens/project_form_screen.dart';
import 'package:task_flow/features/settings/presentation/screens/settings_screen.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:task_flow/features/tasks/presentation/screens/task_form_screen.dart';

class AppRouter {
  final SessionCubit sessionCubit;

  AppRouter(this.sessionCubit);

  late final router = GoRouter(
    initialLocation: AppConstants.routeSplash,
    refreshListenable: _GoRouterRefreshStream(sessionCubit.stream),
    redirect: (context, state) {
      final sessionState = sessionCubit.state;
      final goingToSplash = state.matchedLocation == AppConstants.routeSplash;
      final goingToAuth = state.matchedLocation == AppConstants.routeLogin ||
          state.matchedLocation == AppConstants.routeRegister;

      // During initial load / splash check
      if (sessionState is SessionInitial || sessionState is SessionLoading) {
        return goingToSplash ? null : AppConstants.routeSplash;
      }

      // If user is not authenticated
      if (sessionState is SessionUnauthenticated ||
          sessionState is SessionTokenExpired) {
        if (goingToAuth) return null;
        return AppConstants.routeLogin;
      }

      // If user is authenticated
      // Don't redirect away from splash — the SplashScreen handles biometric
      // prompt and its own navigation via BlocListener.
      if (sessionState is SessionAuthenticated) {
        if (goingToAuth) return AppConstants.routeHome;
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppConstants.routeHome,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppConstants.routeProjectDetail,
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return ProjectDetailScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: AppConstants.routeProjectForm,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final project = extra['project'] as Project?;
          final isAdmin = extra['isAdmin'] as bool? ?? false;
          return ProjectFormScreen(
            project: project,
            isAdmin: isAdmin,
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeTaskDetail,
        builder: (context, state) {
          final taskId = state.pathParameters['taskId']!;
          return TaskDetailScreen(taskId: taskId);
        },
      ),
      GoRoute(
        path: AppConstants.routeTaskForm,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final projectId = extra['projectId'] as String? ?? '';
          final task = extra['task'] as TaskEntity?;
          return TaskFormScreen(
            projectId: projectId,
            task: task,
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeSettings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription =
        stream.asBroadcastStream().listen((dynamic _) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
