import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_flow/features/auth/presentation/cubit/login_cubit.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';
import 'package:task_flow/features/auth/presentation/screens/login_screen.dart';

class MockSessionCubit extends Mock implements SessionCubit {}

class FakeLoginCubit extends Cubit<LoginState> implements LoginCubit {
  FakeLoginCubit() : super(const LoginInitial());

  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  void reset() => emit(const LoginInitial());
}

void main() {
  late MockSessionCubit mockSession;

  setUp(() {
    mockSession = MockSessionCubit();
    when(() => mockSession.state).thenReturn(const SessionInitial());
  });

  Widget buildTestWidget({LoginCubit? loginCubit}) {
    final cubit = loginCubit ?? FakeLoginCubit();
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: mockSession),
          BlocProvider<LoginCubit>.value(value: cubit),
        ],
        child: const LoginScreen(),
      ),
    );
  }

  group('Login form validation', () {
    testWidgets('renders login form elements', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('TaskFlow'), findsOneWidget);
    });

    testWidgets('shows error when email is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('shows error for invalid email', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows error when password is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@email.com',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@email.com',
      );
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('has register link', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Create account'), findsOneWidget);
    });
  });
}
