import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/core/network/connectivity_cubit.dart';
import 'package:task_flow/core/theme/theme_cubit.dart';
import 'package:task_flow/features/auth/presentation/cubit/login_cubit.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';
import 'package:task_flow/features/auth/presentation/screens/login_screen.dart';
import 'package:task_flow/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_form_cubit.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_list_cubit.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_flow/features/tasks/presentation/cubit/task_detail_cubit.dart';
import 'package:task_flow/features/tasks/presentation/cubit/task_form_cubit.dart';
import 'package:task_flow/features/users/presentation/cubit/org_members_cubit.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockSessionCubit extends Mock implements SessionCubit {}
class MockThemeCubit extends Mock implements ThemeCubit {}
class MockConnectivityCubit extends Mock implements ConnectivityCubit {}
class MockProjectListCubit extends Mock implements ProjectListCubit {}
class MockProjectFormCubit extends Mock implements ProjectFormCubit {}
class MockTaskBloc extends Mock implements TaskBloc {}
class MockTaskFormCubit extends Mock implements TaskFormCubit {}
class MockTaskDetailCubit extends Mock implements TaskDetailCubit {}
class MockOrgMembersCubit extends Mock implements OrgMembersCubit {}
class MockNotificationCubit extends Mock implements NotificationCubit {}

class FakeLoginCubit extends Cubit<LoginState> implements LoginCubit {
  final SessionCubit _session;
  FakeLoginCubit(this._session) : super(const LoginInitial());

  @override
  Future<void> login({required String email, required String password}) async {
    emit(const LoginLoading());
    final error = await _session.login(email: email, password: password);
    if (!isClosed) {
      if (error == null) {
        emit(const LoginSuccess());
      } else {
        emit(LoginFailure(error));
      }
    }
  }

  @override
  void reset() => emit(const LoginInitial());
}

void main() {
  late MockSessionCubit mockSession;

  setUp(() {
    mockSession = MockSessionCubit();
    when(() => mockSession.state).thenReturn(const SessionInitial());
    when(() => mockSession.login(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => 'Invalid email or password');
  });

  Widget buildApp() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: mockSession),
          BlocProvider<LoginCubit>.value(value: FakeLoginCubit(mockSession)),
          BlocProvider<ThemeCubit>.value(value: MockThemeCubit()),
          BlocProvider<ConnectivityCubit>.value(value: MockConnectivityCubit()),
          BlocProvider<ProjectListCubit>.value(value: MockProjectListCubit()),
          BlocProvider<ProjectFormCubit>.value(value: MockProjectFormCubit()),
          BlocProvider<TaskBloc>.value(value: MockTaskBloc()),
          BlocProvider<TaskFormCubit>.value(value: MockTaskFormCubit()),
          BlocProvider<TaskDetailCubit>.value(value: MockTaskDetailCubit()),
          BlocProvider<OrgMembersCubit>.value(value: MockOrgMembersCubit()),
          BlocProvider<NotificationCubit>.value(value: MockNotificationCubit()),
        ],
        child: const LoginScreen(),
      ),
    );
  }

  group('Login Flow Integration Tests', () {
    testWidgets('renders login screen with all elements', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('TaskFlow'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('validates email format', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('validates password length', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'test@email.com');
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('calls login with correct credentials', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'alice@alphacorp.com');
      await tester.enterText(find.byType(TextFormField).last, 'Password1');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      verify(() => mockSession.login(
        email: 'alice@alphacorp.com',
        password: 'Password1',
      )).called(1);
    });

    testWidgets('shows error snackbar on failed login', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'wrong@email.com');
      await tester.enterText(find.byType(TextFormField).last, 'wrongpass');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
