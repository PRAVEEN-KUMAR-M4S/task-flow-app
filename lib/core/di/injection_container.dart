import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:task_flow/core/mock/error_simulator.dart';
import 'package:task_flow/core/mock/mock_database.dart';
import 'package:task_flow/core/network/connectivity_cubit.dart';
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

final sl = GetIt.instance;

Future<void> init() async {
  // ─── Core / Storage / Connectivity ─────────────────────────────────────────
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(storage: sl()),
  );

  // ─── Repositories ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(datasource: sl(), secureStorage: sl()),
  );

  sl.registerLazySingleton<ConnectivityCubit>(() => ConnectivityCubit());
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());

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

  // ─── Services ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthorizationService>(
    () => AuthorizationService(authRepository: sl()),
  );

  // ─── Use Cases ────────────────────────────────────────────────────────────
  // Auth Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => RefreshTokenUseCase(sl()));
  sl.registerLazySingleton(() => GetCachedSessionUseCase(sl()));

  // ─── Blocs / Cubits ────────────────────────────────────────────────────────
  sl.registerLazySingleton(
    () => SessionCubit(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      refreshTokenUseCase: sl(),
      getCachedSessionUseCase: sl(),
      secureStorage: sl(),
    ),
  );
}
