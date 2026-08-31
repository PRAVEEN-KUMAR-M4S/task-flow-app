import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_flow/core/di/injection_container.dart' as di;
import 'package:task_flow/core/network/connectivity_cubit.dart';
import 'package:task_flow/core/router/app_router.dart';
import 'package:task_flow/core/storage/hive_service.dart';
import 'package:task_flow/core/theme/app_theme.dart';
import 'package:task_flow/core/theme/theme_cubit.dart';
import 'package:task_flow/features/auth/presentation/auth_router_state_impl.dart';
import 'package:task_flow/features/auth/presentation/cubit/login_cubit.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';
import 'package:task_flow/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_detail_cubit.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_form_cubit.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_list_cubit.dart';
import 'package:task_flow/features/tasks/presentation/cubit/task_list_cubit.dart';
import 'package:task_flow/features/tasks/presentation/cubit/task_detail_cubit.dart';
import 'package:task_flow/features/users/presentation/cubit/org_members_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Hive cache
  await Hive.initFlutter();
  await HiveService.openBoxes();

  // Initialize Dependency Injection
  await di.init();

  // Load persisted theme preference
  await di.sl<ThemeCubit>().loadTheme();

  runApp(const TaskFlowApp());
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => di.sl<ThemeCubit>()),
        BlocProvider<SessionCubit>(create: (_) => di.sl<SessionCubit>()),
        BlocProvider<ConnectivityCubit>(
          create: (_) => di.sl<ConnectivityCubit>(),
        ),
        BlocProvider<NotificationCubit>(
          create: (_) => di.sl<NotificationCubit>(),
        ),
        BlocProvider<ProjectListCubit>(
          create: (_) => di.sl<ProjectListCubit>(),
        ),
        BlocProvider<TaskListCubit>(create: (_) => di.sl<TaskListCubit>()),
        BlocProvider<ProjectFormCubit>(
          create: (_) => di.sl<ProjectFormCubit>(),
        ),

        BlocProvider<OrgMembersCubit>(create: (_) => di.sl<OrgMembersCubit>()),
        BlocProvider<LoginCubit>(create: (_) => di.sl<LoginCubit>()),
        BlocProvider<ProjectDetailCubit>(
          create: (_) => di.sl<ProjectDetailCubit>(),
        ),
        BlocProvider<TaskDetailCubit>(create: (_) => di.sl<TaskDetailCubit>()),
      ],
      child: const TaskFlowAppMaterial(),
    );
  }
}

class TaskFlowAppMaterial extends StatefulWidget {
  const TaskFlowAppMaterial({super.key});

  @override
  State<TaskFlowAppMaterial> createState() => _TaskFlowAppMaterialState();
}

class _TaskFlowAppMaterialState extends State<TaskFlowAppMaterial> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    final sessionCubit = context.read<SessionCubit>();
    final authRouterState = AuthRouterStateImpl(sessionCubit);
    _appRouter = AppRouter(authRouterState);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;

    return MaterialApp.router(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _appRouter.router,
    );
  }
}
