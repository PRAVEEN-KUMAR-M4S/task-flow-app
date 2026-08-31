import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:task_flow/core/mock/error_simulator.dart';
import 'package:task_flow/core/mock/mock_database.dart';
import 'package:task_flow/core/network/connectivity_cubit.dart';
import 'package:task_flow/core/services/biometric_service.dart';
import 'package:task_flow/core/storage/secure_storage_service.dart';
import 'package:task_flow/core/theme/theme_cubit.dart';

// Auth
import 'package:task_flow/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:task_flow/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:task_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:task_flow/features/auth/domain/services/authorization_service.dart';
import 'package:task_flow/features/auth/domain/usecases/get_cached_session_usecase.dart';
import 'package:task_flow/features/auth/domain/usecases/login_usecase.dart';
import 'package:task_flow/features/auth/domain/usecases/logout_usecase.dart';
import 'package:task_flow/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';

// Projects
import 'package:task_flow/features/projects/data/datasources/project_local_datasource.dart';
import 'package:task_flow/features/projects/data/repositories/project_repository_impl.dart';
import 'package:task_flow/features/projects/domain/repositories/project_repository.dart';
import 'package:task_flow/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:task_flow/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:task_flow/features/projects/domain/usecases/get_project_detail_usecase.dart';
import 'package:task_flow/features/projects/domain/usecases/get_projects_usecase.dart';
import 'package:task_flow/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_detail_cubit.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_form_cubit.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_list_cubit.dart';

// Tasks
import 'package:task_flow/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:task_flow/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';
import 'package:task_flow/features/tasks/domain/usecases/assign_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_comments_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_task_detail_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/update_task_status_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:task_flow/features/tasks/presentation/cubit/task_list_cubit.dart';
import 'package:task_flow/features/tasks/presentation/cubit/task_detail_cubit.dart';
import 'package:task_flow/features/auth/presentation/cubit/login_cubit.dart';

// Users
import 'package:task_flow/features/users/data/datasources/user_local_datasource.dart';
import 'package:task_flow/features/users/data/repositories/user_repository_impl.dart';
import 'package:task_flow/features/users/domain/repositories/user_repository.dart';
import 'package:task_flow/features/users/domain/usecases/get_org_members_usecase.dart';
import 'package:task_flow/features/users/domain/usecases/validate_org_membership_usecase.dart';
import 'package:task_flow/features/users/presentation/cubit/org_members_cubit.dart';

// Notifications
import 'package:task_flow/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:task_flow/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:task_flow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:task_flow/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:task_flow/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:task_flow/features/notifications/presentation/cubit/notification_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ─── Core / Storage / Connectivity ─────────────────────────────────────────
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(storage: sl()),
  );

  sl.registerLazySingleton<ConnectivityCubit>(() => ConnectivityCubit());
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(secureStorage: sl()));

  // ─── Mock Infrastructure ───────────────────────────────────────────────────
  sl.registerLazySingleton<MockDatabase>(() => MockDatabase());
  sl.registerLazySingleton<ErrorSimulator>(() => ErrorSimulator());

  // ─── Datasources ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthLocalDatasource>(
    () => AuthLocalDatasourceImpl(
      secureStorage: sl(),
      database: sl(),
      errorSimulator: sl(),
    ),
  );
  sl.registerLazySingleton<ProjectLocalDatasource>(
    () => ProjectLocalDatasourceImpl(database: sl(), errorSimulator: sl()),
  );
  sl.registerLazySingleton<TaskLocalDatasource>(
    () => TaskLocalDatasourceImpl(database: sl(), errorSimulator: sl()),
  );
  sl.registerLazySingleton<UserLocalDatasource>(
    () => UserLocalDatasourceImpl(database: sl(), errorSimulator: sl()),
  );
  sl.registerLazySingleton<NotificationLocalDatasource>(
    () => NotificationLocalDatasourceImpl(database: sl(), errorSimulator: sl()),
  );

  // ─── Repositories ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(datasource: sl(), secureStorage: sl()),
  );
  sl.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(datasource: sl(), connectivity: sl()),
  );
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(datasource: sl(), connectivity: sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(datasource: sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(datasource: sl(), connectivity: sl()),
  );

  // ─── Services ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthorizationService>(
    () => AuthorizationService(authRepository: sl()),
  );
  sl.registerLazySingleton<BiometricService>(() => BiometricService());

  // ─── Use Cases ────────────────────────────────────────────────────────────
  // Auth Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => RefreshTokenUseCase(sl()));
  sl.registerLazySingleton(() => GetCachedSessionUseCase(sl()));

  // Projects Use Cases
  sl.registerLazySingleton(() => GetProjectsUseCase(sl(), authorization: sl()));
  sl.registerLazySingleton(
    () => GetProjectDetailUseCase(sl(), authorization: sl()),
  );
  sl.registerLazySingleton(
    () => CreateProjectUseCase(sl(), authorization: sl()),
  );
  sl.registerLazySingleton(
    () => UpdateProjectUseCase(sl(), authorization: sl()),
  );
  sl.registerLazySingleton(
    () => DeleteProjectUseCase(sl(), authorization: sl()),
  );

  // Tasks Use Cases
  sl.registerLazySingleton(() => GetTasksUseCase(sl()));
  sl.registerLazySingleton(() => GetTaskDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetCommentsUseCase(sl()));
  sl.registerLazySingleton(() => CreateTaskUseCase(sl()));
  sl.registerLazySingleton(
    () => UpdateTaskUseCase(repository: sl(), userRepository: sl()),
  );
  sl.registerLazySingleton(() => DeleteTaskUseCase(sl()));
  sl.registerLazySingleton(
    () => AssignTaskUseCase(taskRepository: sl(), userRepository: sl()),
  );
  sl.registerLazySingleton(() => UpdateTaskStatusUseCase(sl()));

  // Users Use Cases
  sl.registerLazySingleton(() => GetOrgMembersUseCase(sl()));
  sl.registerLazySingleton(() => ValidateOrgMembershipUseCase(sl()));

  // Notifications Use Cases
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));

  // ─── Blocs / Cubits ────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => LoginCubit(sessionCubit: sl()));

  sl.registerLazySingleton(
    () => SessionCubit(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      refreshTokenUseCase: sl(),
      getCachedSessionUseCase: sl(),
      secureStorage: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => ProjectListCubit(
      getProjectsUseCase: sl(),
      createProjectUseCase: sl(),
      updateProjectUseCase: sl(),
      deleteProjectUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => ProjectDetailCubit(getProjectDetailUseCase: sl()),
  );

  sl.registerLazySingleton(
    () => TaskListCubit(
      getTasksUseCase: sl(),
      createTaskUseCase: sl(),
      updateTaskUseCase: sl(),
      deleteTaskUseCase: sl(),
      favoriteUsecases: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => TaskDetailCubit(
      getTaskDetailUseCase: sl(),
      getCommentsUseCase: sl(),
      assignTaskUseCase: sl(),
      updateTaskStatusUseCase: sl(),
      deleteTaskUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => OrgMembersCubit(getOrgMembersUseCase: sl()));

  // Form Cubits (lazy singletons — provided at app root, reset() before each use)
  sl.registerLazySingleton(
    () => ProjectFormCubit(
      createProjectUseCase: sl(),
      updateProjectUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => NotificationCubit(
      getNotificationsUseCase: sl(),
      markNotificationReadUseCase: sl(),
      repository: sl(),
    ),
  );
}
