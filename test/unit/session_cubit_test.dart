import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/storage/secure_storage_service.dart';
import 'package:task_flow/features/auth/domain/entities/user.dart';
import 'package:task_flow/features/auth/domain/usecases/get_cached_session_usecase.dart';
import 'package:task_flow/features/auth/domain/usecases/login_usecase.dart';
import 'package:task_flow/features/auth/domain/usecases/logout_usecase.dart';
import 'package:task_flow/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockRefreshTokenUseCase extends Mock implements RefreshTokenUseCase {}
class MockGetCachedSessionUseCase extends Mock implements GetCachedSessionUseCase {}
class MockSecureStorage extends Mock implements SecureStorageService {}

void main() {
  late SessionCubit cubit;
  late MockLoginUseCase mockLogin;
  late MockLogoutUseCase mockLogout;
  late MockRefreshTokenUseCase mockRefresh;
  late MockGetCachedSessionUseCase mockGetCached;
  late MockSecureStorage mockStorage;

  const testUser = User(
    id: 'user_001',
    name: 'Alice Anderson',
    email: 'alice@alphacorp.com',
    avatarUrl: null,
    orgId: 'org_a1b2c3',
    orgName: 'AlphaCorp',
    role: 'org_admin',
  );

  setUpAll(() {
    registerFallbackValue(const LoginParams(email: '', password: ''));
  });

  setUp(() {
    mockLogin = MockLoginUseCase();
    mockLogout = MockLogoutUseCase();
    mockRefresh = MockRefreshTokenUseCase();
    mockGetCached = MockGetCachedSessionUseCase();
    mockStorage = MockSecureStorage();

    // Stub storage methods that SessionCubit calls internally
    when(() => mockStorage.getTokenExpiry()).thenAnswer((_) async => null);
    when(() => mockStorage.getRefreshToken()).thenAnswer((_) async => null);

    cubit = SessionCubit(
      loginUseCase: mockLogin,
      logoutUseCase: mockLogout,
      refreshTokenUseCase: mockRefresh,
      getCachedSessionUseCase: mockGetCached,
      secureStorage: mockStorage,
    );
  });

  tearDown(() => cubit.close());

  group('SessionCubit', () {
    test('initial state is SessionInitial', () {
      expect(cubit.state, isA<SessionInitial>());
    });

    group('checkSession', () {
      blocTest<SessionCubit, SessionState>(
        'emits SessionLoading → SessionAuthenticated when cached user exists',
        build: () {
          when(() => mockGetCached()).thenAnswer(
            (_) async => Right<Failure, User?>(testUser),
          );
          return cubit;
        },
        act: (cubit) => cubit.checkSession(),
        expect: () => [
          isA<SessionLoading>(),
          predicate<SessionState>((s) =>
              s is SessionAuthenticated && s.user.id == 'user_001'),
        ],
      );

      blocTest<SessionCubit, SessionState>(
        'emits SessionLoading → SessionUnauthenticated when no cached user',
        build: () {
          when(() => mockGetCached()).thenAnswer(
            (_) async => Right<Failure, User?>(null),
          );
          return cubit;
        },
        act: (cubit) => cubit.checkSession(),
        expect: () => [
          isA<SessionLoading>(),
          isA<SessionUnauthenticated>(),
        ],
      );

      blocTest<SessionCubit, SessionState>(
        'emits SessionLoading → SessionUnauthenticated on failure',
        build: () {
          when(() => mockGetCached()).thenAnswer(
            (_) async => Left<Failure, User?>(
              const ServerFailure(message: 'Cache error'),
            ),
          );
          return cubit;
        },
        act: (cubit) => cubit.checkSession(),
        expect: () => [
          isA<SessionLoading>(),
          isA<SessionUnauthenticated>(),
        ],
      );
    });

    group('login', () {
      blocTest<SessionCubit, SessionState>(
        'emits SessionLoading → SessionAuthenticated on success',
        build: () {
          when(() => mockLogin(any())).thenAnswer(
            (_) async => Right<Failure, User>(testUser),
          );
          return cubit;
        },
        act: (cubit) => cubit.login(email: 'alice@alphacorp.com', password: 'password'),
        expect: () => [
          isA<SessionLoading>(),
          predicate<SessionState>((s) =>
              s is SessionAuthenticated && s.user.email == 'alice@alphacorp.com'),
        ],
        verify: (_) => verify(() => mockLogin(any())).called(1),
      );

      blocTest<SessionCubit, SessionState>(
        'emits SessionLoading → SessionUnauthenticated on wrong credentials',
        build: () {
          when(() => mockLogin(any())).thenAnswer(
            (_) async => Left<Failure, User>(
              const InvalidCredentialsFailure(),
            ),
          );
          return cubit;
        },
        act: (cubit) => cubit.login(email: 'wrong@email.com', password: 'bad'),
        expect: () => [
          isA<SessionLoading>(),
          isA<SessionUnauthenticated>(),
        ],
      );

      test('login returns error message on failure', () async {
        when(() => mockLogin(any())).thenAnswer(
          (_) async => Left<Failure, User>(
            const InvalidCredentialsFailure(),
          ),
        );

        final error = await cubit.login(email: 'x', password: 'y');
        expect(error, isNotNull);
        expect(error, contains('Invalid'));
      });

      test('login returns null on success', () async {
        when(() => mockLogin(any())).thenAnswer(
          (_) async => Right<Failure, User>(testUser),
        );

        final error = await cubit.login(email: 'x', password: 'y');
        expect(error, isNull);
      });
    });

    group('logout', () {
      blocTest<SessionCubit, SessionState>(
        'emits SessionUnauthenticated',
        build: () {
          when(() => mockLogout()).thenAnswer(
            (_) async => const Right<Failure, Unit>(unit),
          );
          return cubit;
        },
        seed: () => const SessionAuthenticated(testUser),
        act: (cubit) => cubit.logout(),
        expect: () => [isA<SessionUnauthenticated>()],
        verify: (_) => verify(() => mockLogout()).called(1),
      );
    });

    group('currentUser', () {
      test('returns user when authenticated', () {
        cubit.emit(const SessionAuthenticated(testUser));
        expect(cubit.currentUser?.id, 'user_001');
      });

      test('returns null when not authenticated', () {
        cubit.emit(const SessionUnauthenticated());
        expect(cubit.currentUser, isNull);
      });
    });
  });
}
