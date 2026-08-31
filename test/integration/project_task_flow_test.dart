import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_flow/core/network/connectivity_cubit.dart';
import 'package:task_flow/core/theme/theme_cubit.dart';
import 'package:task_flow/features/auth/domain/entities/user.dart';
import 'package:task_flow/features/auth/presentation/cubit/login_cubit.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';
import 'package:task_flow/features/home/presentation/screens/home_screen.dart';
import 'package:task_flow/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_form_cubit.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_list_cubit.dart';
import 'package:task_flow/features/tasks/presentation/cubit/task_list_cubit.dart';
import 'package:task_flow/features/tasks/presentation/cubit/task_detail_cubit.dart';
import 'package:task_flow/features/users/presentation/cubit/org_members_cubit.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockSessionCubit extends Mock implements SessionCubit {}
class MockThemeCubit extends Mock implements ThemeCubit {}
class MockConnectivityCubit extends Mock implements ConnectivityCubit {}
class MockProjectFormCubit extends Mock implements ProjectFormCubit {}
class MockTaskListCubit extends Mock implements TaskListCubit {}
class MockTaskDetailCubit extends Mock implements TaskDetailCubit {}
class MockOrgMembersCubit extends Mock implements OrgMembersCubit {}
class MockNotificationCubit extends Mock implements NotificationCubit {}
class MockLoginCubit extends Mock implements LoginCubit {}

class FakeProjectListCubit extends Cubit<ProjectListState>
    implements ProjectListCubit {
  FakeProjectListCubit() : super(const ProjectListInitial());

  @override
  String? get currentOrgId => 'org_a1b2c3';

  @override
  Future<void> loadProjects({required String orgId}) async {
    emit(const ProjectListLoading());
    emit(const ProjectListEmpty());
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<String?> createProject({
    required String orgId,
    required String name,
    required String description,
  }) async => null;

  @override
  Future<String?> updateProject({
    required String id,
    required String name,
    required String description,
    required String status,
  }) async => null;

  @override
  Future<String?> deleteProject({required String id}) async => null;
}

void main() {
  late MockSessionCubit mockSession;
  late MockNotificationCubit mockNotification;
  late MockProjectFormCubit mockProjectForm;
  late MockTaskListCubit mockTaskList;
  late MockTaskDetailCubit mockTaskDetail;
  late MockOrgMembersCubit mockOrgMembers;

  setUp(() {
    mockSession = MockSessionCubit();
    mockNotification = MockNotificationCubit();
    mockProjectForm = MockProjectFormCubit();
    mockTaskList = MockTaskListCubit();
    mockTaskDetail = MockTaskDetailCubit();
    mockOrgMembers = MockOrgMembersCubit();

    when(() => mockSession.state).thenReturn(
      const SessionAuthenticated(
        User(
          id: 'user_001',
          name: 'Alice',
          email: 'alice@alphacorp.com',
          avatarUrl: null,
          orgId: 'org_a1b2c3',
          orgName: 'AlphaCorp',
          role: 'org_admin',
        ),
      ),
    );
    when(() => mockSession.currentUser).thenReturn(
      const User(
        id: 'user_001',
        name: 'Alice',
        email: 'alice@alphacorp.com',
        avatarUrl: null,
        orgId: 'org_a1b2c3',
        orgName: 'AlphaCorp',
        role: 'org_admin',
      ),
    );
    when(() => mockSession.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockTaskList.state).thenReturn(const TaskListInitial());
    when(() => mockTaskList.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockTaskDetail.state).thenReturn(const TaskDetailInitial());
    when(() => mockTaskDetail.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockNotification.state).thenReturn(const NotificationInitial());
    when(() => mockNotification.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockProjectForm.state).thenReturn(const ProjectFormInitial());
    when(() => mockProjectForm.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockOrgMembers.state).thenReturn(const OrgMembersInitial());
    when(() => mockOrgMembers.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockNotification.unreadCount).thenReturn(0);
    when(() => mockNotification.loadNotifications(any())).thenAnswer((_) async {});
    when(() => mockNotification.markAsRead(any())).thenAnswer((_) async {});
  });

  Widget buildApp() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: mockSession),
          BlocProvider<LoginCubit>.value(value: MockLoginCubit()),
          BlocProvider<ThemeCubit>.value(value: MockThemeCubit()),
          BlocProvider<ConnectivityCubit>.value(value: MockConnectivityCubit()),
          BlocProvider<ProjectListCubit>.value(value: FakeProjectListCubit()),
          BlocProvider<ProjectFormCubit>.value(value: mockProjectForm),
          BlocProvider<TaskListCubit>.value(value: mockTaskList),
          BlocProvider<TaskDetailCubit>.value(value: mockTaskDetail),
          BlocProvider<OrgMembersCubit>.value(value: mockOrgMembers),
          BlocProvider<NotificationCubit>.value(value: mockNotification),
        ],
        child: const HomeScreen(),
      ),
    );
  }

  group('Navigation Integration Tests', () {
    testWidgets('home screen shows bottom navigation', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Projects'), findsWidgets);
      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('bottom nav switches tabs', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('settings accessible from profile tab', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('Project List Integration Tests', () {
    testWidgets('shows projects tab by default', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Projects'), findsWidgets);
    });
  });
}
