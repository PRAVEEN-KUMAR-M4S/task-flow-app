# TaskFlow — Project Management App

A Flutter project management application built with **Clean Architecture**, **Bloc/Cubit** state management, and a fully mocked data layer. Designed as a demonstration of scalable Flutter patterns — no real network calls, all data served from a single local mock JSON asset.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Folder Structure](#folder-structure)
- [State Management](#state-management)
- [Mock Data Layer](#mock-data-layer)
- [Authentication & Token Flow](#authentication--token-flow)
- [Simulated Error & Offline States](#simulated-error--offline-states)
- [Local Setup](#local-setup)
- [How to Run](#how-to-run)
- [How to Test](#how-to-test)
- [How to Build APK](#how-to-build-apk)
- [Test Credentials](#test-credentials)
- [Screens](#screens)
- [Known Limitations & Trade-offs](#known-limitations--trade-offs)

---

## Project Overview

**TaskFlow** is a task and project management app for organizations. Users belong to an organization and can be either `org_admin` or `member`. Admins can create, edit, and delete projects; members can manage tasks within their assigned projects.

All data is served from a single `assets/mock_data/mock-data.json` file parsed through a layered data-source and repository system. The app simulates real-world backend behaviors including token expiry, token refresh, network errors, offline mode, and artificial latency.

### Key capabilities

- **Simulated authentication** — login, register, session persistence, 15-minute token expiry with automatic refresh, biometric unlock
- **Project management** — create, edit, delete projects (admin-only delete enforced at business-logic layer)
- **Task management** — create, edit, delete, assign/unassign, status/priority updates, filters
- **Offline awareness** — Hive caching, connectivity toggle, stale-data banners
- **Error simulation** — three trigger mechanisms for 404, timeout, and validation errors
- **Skeleton loading** — shimmer-animated placeholders on all list screens
- **Dark mode** — full light/dark theme support
- **70 automated tests** — unit, widget, and integration

---

## Architecture

The app follows **Clean Architecture** with three clear layers per feature:

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                  │
│  Screens (Widgets) ← Cubits / Blocs ← Use Cases    │
├─────────────────────────────────────────────────────┤
│                    Domain Layer                      │
│  Entities ← Repository Interfaces ← Use Cases       │
├─────────────────────────────────────────────────────┤
│                     Data Layer                       │
│  Datasources → Models → Repository Implementations  │
└─────────────────────────────────────────────────────┘
```

### Key principles

- **Domain layer** defines entities (`Project`, `TaskEntity`, `User`, `AuthToken`) and repository interfaces. No Flutter or platform dependencies.
- **Data layer** implements those interfaces. Datasources read/write `MockDatabase`. Models handle JSON serialization with `json_serializable`. This layer is the only place that touches the asset file.
- **Presentation layer** contains screens (widgets), Cubits/Blocs (state), and nothing else. No `rootBundle.loadString`, no direct JSON access.
- **Dependency injection** via `get_it` wires everything together at startup. All blocs/cubits are registered as lazy singletons.

### Dependency Injection pattern

```
injection_container.dart          main.dart                     Screens
┌────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│ registerLazySingleton│──→│ MultiBlocProvider     │──→│ context.read<X>()   │
│ for ALL instances   │    │ provides ALL singletons│   │ BlocBuilder         │
│ (repos, use cases,  │    │ to the widget tree    │    │ BlocListener        │
│  cubits, blocs)     │    │                       │    │                     │
└────────────────────┘    └──────────────────────┘    └─────────────────────┘
```

**Rule**: Screens **never** create `BlocProvider(create:)`. All providers come from the root `MultiBlocProvider` in `main.dart`. Screens call `context.read<X>()` and `BlocBuilder<X, XState>` only.

### Cross-cutting concerns live in `core/`

| Module | Responsibility |
|---|---|
| `core/constants/` | Route names, storage keys, simulation config, error-trigger tokens |
| `core/di/` | `get_it` service locator setup |
| `core/error/` | `Failure` hierarchy, `Exception` types, `failure_mapper` |
| `core/mock/` | `MockDatabase` (in-memory DB seeded from asset), `ErrorSimulator` (debug toggle) |
| `core/network/` | `ConnectivityCubit` (offline toggle), `MockDatasourceMixin` (simulated delay + error checking) |
| `core/router/` | `GoRouter` config with auth redirect guard |
| `core/services/` | `BiometricService` (local_auth integration) |
| `core/storage/` | `SecureStorageService` (tokens via `flutter_secure_storage`), `HiveService` (offline cache) |
| `core/theme/` | `AppTheme` (light/dark Material 3), `ThemeCubit` |
| `core/usecase/` | Base `UseCase` and `UseCaseNoParams` abstract classes |
| `core/utils/` | `Cached<T>` wrapper, `Either` extensions |

---

## Folder Structure

```
lib/
├── main.dart                          # App entry, root MultiBlocProvider, DI init
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Routes, storage keys, simulation config
│   ├── di/
│   │   └── injection_container.dart   # GetIt registration — ALL instances
│   ├── error/
│   │   ├── exceptions.dart            # NotFoundException, TimeoutException, etc.
│   │   ├── failures.dart              # Failure hierarchy (NetworkFailure, etc.)
│   │   └── failure_mapper.dart        # Exception → Failure mapping
│   ├── mock/
│   │   ├── mock_database.dart         # In-memory DB seeded from JSON asset
│   │   └── error_simulator.dart       # Debug toggle: arm/disarm forced errors
│   ├── network/
│   │   ├── connectivity_cubit.dart    # Online/offline state
│   │   └── mock_datasource_mixin.dart # Simulated delay + error-trigger checking
│   ├── router/
│   │   └── app_router.dart            # GoRouter with auth redirect guard
│   ├── services/
│   │   └── biometric_service.dart     # local_auth integration
│   ├── storage/
│   │   ├── secure_storage_service.dart # Token storage (flutter_secure_storage)
│   │   └── hive_service.dart          # Offline cache (Hive)
│   ├── theme/
│   │   ├── app_theme.dart             # Material 3 light/dark themes
│   │   └── theme_cubit.dart           # Theme mode state
│   ├── usecase/
│   │   └── usecase.dart               # Base UseCase<T, Params> abstract class
│   └── utils/
│       ├── cached.dart                # Cached<T> wrapper (fresh vs stale)
│       └── either_extensions.dart     # Either helper extensions
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/auth_local_datasource.dart
│   │   │   ├── models/                # AuthResponseModel, UserModel, TestCredentialModel
│   │   │   └── repositories/auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/              # AuthToken, User, TestCredential
│   │   │   ├── repositories/auth_repository.dart
│   │   │   ├── services/authorization_service.dart
│   │   │   └── usecases/              # Login, Logout, RefreshToken, GetCachedSession
│   │   └── presentation/
│   │       ├── cubit/                 # SessionCubit, LoginCubit
│   │       ├── screens/               # SplashScreen, LoginScreen, RegisterScreen
│   │       └── widgets/               # AuthTextField
│   ├── projects/
│   │   ├── data/
│   │   │   ├── datasources/project_local_datasource.dart
│   │   │   ├── models/                # ProjectModel
│   │   │   └── repositories/project_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/project.dart
│   │   │   ├── repositories/project_repository.dart
│   │   │   └── usecases/              # GetProjects, GetProjectDetail, Create, Update, Delete
│   │   └── presentation/
│   │       ├── cubit/                 # ProjectListCubit, ProjectDetailCubit, ProjectFormCubit
│   │       ├── screens/               # ProjectListScreen, ProjectDetailScreen, ProjectFormScreen
│   │       └── widgets/               # ProjectCard, TaskSummaryRow, SkeletonProjectCard
│   ├── tasks/
│   │   ├── data/
│   │   │   ├── datasources/task_local_datasource.dart
│   │   │   ├── models/                # TaskModel
│   │   │   └── repositories/task_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/              # TaskEntity, TaskFilter
│   │   │   ├── repositories/task_repository.dart
│   │   │   └── usecases/              # GetTasks, GetTaskDetail, Create, Update, Delete, Assign, UpdateStatus
│   │   └── presentation/
│   │       ├── bloc/task_bloc.dart     # TaskBloc (events + states)
│   │       ├── cubit/                 # TaskDetailCubit, TaskFormCubit
│   │       ├── screens/               # TaskDetailScreen, TaskFormScreen
│   │       └── widgets/               # TaskCard, TaskFilterBar, AssigneePickerBottomSheet, StatusChip, PriorityBadge
│   ├── users/
│   │   ├── data/                      # UserLocalDatasource, UserRepositoryImpl
│   │   └── domain/                    # OrgMember entity, GetOrgMembers, ValidateOrgMembership
│   ├── notifications/
│   │   ├── data/                      # NotificationLocalDatasource, NotificationRepositoryImpl
│   │   ├── domain/                    # Notification entity, GetNotifications, MarkNotificationRead
│   │   └── presentation/             # NotificationCubit, NotificationsScreen
│   ├── home/presentation/screens/     # HomeScreen (bottom nav)
│   ├── profile/presentation/screens/  # ProfileScreen
│   └── settings/presentation/screens/ # SettingsScreen (dark mode, offline, error sim)
└── shared/
    └── widgets/                       # Reusable: LoadingView, EmptyView, ErrorView, ConfirmDialog,
                                       #   AppAvatar, AppButton, StaleDataBanner,
                                       #   SkeletonLoader, SkeletonBox, SkeletonCircle,
                                       #   SkeletonProjectCard, SkeletonTaskCard
```

---

## State Management

The app uses **flutter_bloc** (Bloc/Cubit pattern) consistently across all features.

### State lifecycle pattern

Every feature follows the same lifecycle states:

```
Initial → Loading → Success / Empty / Error
```

### Bloc vs Cubit usage

| Pattern | Used for | Rationale |
|---|---|---|
| **Bloc** (events + states) | `TaskBloc` | Complex multi-operation management with concurrent filter/mutation events |
| **Cubit** (state-only) | All others | Simpler state transitions, fewer event types |

### All Blocs/Cubits (root-level singletons)

All are registered as `registerLazySingleton` in `injection_container.dart` and provided at app root via `MultiBlocProvider` in `main.dart`:

| Cubit/Bloc | States | Purpose |
|---|---|---|
| `SessionCubit` | Initial, Loading, Authenticated, Unauthenticated, TokenExpired, BiometricRequired | Auth session, token refresh timer |
| `LoginCubit` | Initial, Loading, Success, Failure | Login form state |
| `ThemeCubit` | ThemeMode (light/dark) | Theme persistence |
| `ConnectivityCubit` | Online, Offline | Simulated connectivity |
| `ProjectListCubit` | Initial, Loading, Success, Empty, Error, MutationLoading | Project CRUD + list |
| `ProjectDetailCubit` | Loading, Success, Error | Single project detail |
| `ProjectFormCubit` | Initial, Loading, Success, Failure | Project create/edit form |
| `TaskBloc` | Initial, Loading, Success, Empty, Error | Task CRUD + filtering |
| `TaskDetailCubit` | Loading, Success, Error | Single task detail |
| `TaskFormCubit` | Initial, Loading, Success, Failure | Task create/edit form |
| `OrgMembersCubit` | Initial, Loading, Success, Empty, Error | Org member list for assignee pickers |
| `NotificationCubit` | Initial, Loading, Success, Empty, Error | Notification inbox |

### Navigation state management

`GoRouter` is wired to `SessionCubit.stream` via `refreshListenable`, so route redirects react automatically to auth state changes (login → home, logout → login).

---

## Mock Data Layer

### How it's structured

A single file `assets/mock_data/mock-data.json` contains all entities as top-level keys:

```json
{
  "organizations": [...],
  "users": [...],
  "org_members": [...],
  "projects": [...],
  "tasks": [...],
  "comments": [...],
  "notifications": [...],
  "auth_mock": {
    "test_credentials": [...],
    "mock_login_response": {
      "access_token": "mock.access.token.short_lived",
      "refresh_token": "mock.refresh.token.long_lived",
      "access_token_expires_in_seconds": 900,
      "refresh_token_expires_in_seconds": 604800
    }
  }
}
```

### MockDatabase (in-memory store)

`MockDatabase` (`core/mock/mock_database.dart`) is an in-memory, mutable stand-in for a remote database:

1. Loads and parses the JSON asset **once** via `ensureLoaded()` (uses `compute()` for off-main-isolate parsing)
2. Seeds in-memory tables (`organizations`, `users`, `projects`, `tasks`, `comments`, `notifications`, `orgMembers`)
3. All datasources read/write through this single instance — so creating a task through one feature is immediately visible to another

### Data flow

```
JSON Asset → MockDatabase (in-memory) → LocalDatasource (with simulated delay + error check)
         → Repository (with Cached<T> wrapper + offline fallback)
         → UseCase → Cubit/Bloc → Screen
```

### How errors are simulated

Three mechanisms, documented in **Settings → Debug & Simulation**:

#### 1. Error-trigger substrings (data-driven)

`MockDatasourceMixin.checkForSimulatedError()` scans IDs, names, and titles for specific substrings:

| Substring | Error thrown | How to trigger |
|---|---|---|
| `err404` | `NotFoundException` (simulated 404) | Create a task named "Test err404 task" |
| `errTimeout` | `TimeoutException` (simulated timeout) | Create a project named "Report errTimeout" |
| `errValidation` | `ValidationException` (simulated validation) | Create a task with title containing "errValidation" |

You can also **deep link** to a synthetic ID: navigate to `/tasks/task_err404` or `/projects/proj_errTimeout`.

#### 2. Settings → Force Error toggle

The `ErrorSimulator` (`core/mock/error_simulator.dart`) is a debug toggle that forces the **next** data-layer read/write to fail. Access via Settings → Debug & Simulation → "Force Error on Next Request" → pick error type. It auto-resets after firing once.

#### 3. Settings → Simulate Offline Mode

The `ConnectivityCubit` toggle switches between online and offline. When offline:
- Repositories serve cached Hive data (wrapped as `Cached.stale`)
- A `StaleDataBanner` appears at the top of list screens
- Write operations (create/edit/delete) are rejected with a clear error message
- The user can retry when back online

### How delay is simulated

Every datasource operation passes through `MockDatasourceMixin.simulatedDelay()` which adds:
- **Base delay**: 300ms
- **Random jitter**: 0–500ms
- **Total**: 300–800ms

This makes loading states and skeleton UI observable and realistic.

### Offline caching (Hive)

Repositories use a `Cached<T>` wrapper to distinguish fresh vs stale data:

- **Online**: Datasource reads from `MockDatabase`, result wrapped as `Cached.fresh(data)`. Data is also written to Hive for offline access.
- **Offline**: Repository reads from Hive cache, result wrapped as `Cached.stale(data)`.
- The UI shows a `StaleDataBanner` when displaying cached data.
- Writes are **rejected** offline with a clear error message.
- On app restart, Hive-cached data is merged back into `MockDatabase` to preserve user mutations within a session.

---

## Authentication & Token Flow

### Login flow

1. User enters email + password on `LoginScreen` (client-side validation: email format, password length)
2. `LoginCubit` delegates to `SessionCubit.login()`
3. `SessionCubit` calls `LoginUseCase` → `AuthRepository.login()`
4. `AuthRepositoryImpl` calls `AuthLocalDatasource.login()`:
   - Loads `MockDatabase`, finds matching `test_credentials` row
   - Resolves the user from the `users` table
   - Verifies org membership via `org_members`
   - Returns the `mock_login_response` token payload
5. `AuthRepositoryImpl` persists to `SecureStorageService`:
   - `access_token`, `refresh_token`, `user_id`, `org_id`, `token_expiry`
6. `SessionCubit` emits `SessionAuthenticated(user)` and starts the expiry timer

### Token expiry & refresh

The access token expires after **900 seconds (15 minutes)**, as configured by `access_token_expires_in_seconds` in the mock data.

**Timer-based refresh (in-session):**
1. On login, `SessionCubit._startExpiryTimer()` reads the stored `expiresAt` timestamp
2. It schedules a `Timer` to fire just before expiry
3. When the timer fires, `_onTokenExpiry()` calls `RefreshTokenUseCase`
4. The datasource validates the refresh token, reissues the canned token pair, and `toEntity()` stamps a fresh `expiresAt`
5. New tokens are saved to secure storage, and the timer restarts
6. Console log: `[Auth] ⏰ Token expired — attempting refresh...` followed by `[Auth] ✅ Token refreshed successfully`

**App-relaunch refresh:**
1. `SplashScreen` calls `SessionCubit.checkSession()`
2. `GetCachedSessionUseCase` → `AuthRepository.getCachedUser()`
3. `AuthLocalDatasource.getCachedUser()` checks if the access token is still valid
4. If **expired**, it silently attempts a refresh using the stored refresh token
5. On success: new tokens saved, user returned — **no re-login required**
6. On failure (refresh token also expired): returns `null` → user must log in

### Token lifetimes

| Token | Lifetime | Mock value |
|---|---|---|
| Access token | 15 minutes | `access_token_expires_in_seconds: 900` |
| Refresh token | 7 days | `refresh_token_expires_in_seconds: 604800` |

### Logout

`SessionCubit.logout()` → `LogoutUseCase` → clears all secure storage keys → emits `SessionUnauthenticated` → router redirects to `/login`.

### Biometric unlock (bonus)

The app includes a `BiometricService` (`core/services/biometric_service.dart`) using the `local_auth` package for optional biometric (fingerprint/face) unlock of an existing session.

**How it works:**
- When enabled (toggle in Settings → "Biometric Unlock"), the splash screen detects a valid cached session and prompts for biometric authentication
- On success, the user enters the app without re-entering credentials
- On failure, the user must log in normally
- The preference is stored via `SecureStorageService` (key: `biometric_enabled`)

**Requirements:**
- Android: `FragmentActivity` required (configured in the project)
- Device must have biometric hardware and enrolled biometrics

---

## Simulated Error & Offline States

### Quick reference for reviewers

| What to test | How to trigger |
|---|---|
| **404 error** | Create a task named "Test err404" → task creation fails with 404 |
| **Timeout error** | Create a project named "Report errTimeout" → project creation fails with timeout |
| **Validation error** | Create a task with title "errValidation" → task creation fails with validation error |
| **Deep-link 404** | Navigate to `/tasks/task_err404` via URL bar → error screen |
| **Forced error** | Settings → Debug & Simulation → Force Error → pick type → next operation fails |
| **Offline mode** | Settings → Debug & Simulation → toggle "Simulate Offline Mode" → stale data banner, writes rejected |
| **Skeleton loading** | Open Projects tab or tap a project → shimmer placeholders visible during 300-800ms simulated delay |
| **Token expiry** | Wait 15 minutes after login → automatic refresh (check console logs) |
| **Biometric unlock** | Enable in Settings → close and reopen app → biometric prompt on splash |

---

## Local Setup

### Prerequisites

- **Flutter SDK**: `>= 3.10.4` (as specified in `pubspec.yaml`)
- **Dart SDK**: `>= 3.10.4`
- **Android Studio** or **VS Code** with Flutter extension
- **Android emulator / device** (required for Android target)
- **iOS simulator / device** (optional)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd task_flow

# Install dependencies
flutter pub get

# (Optional) Regenerate model code if .g.dart files need updating
dart run build_runner build --delete-conflicting-outputs
```

### Required Android configuration

For biometric authentication (`local_auth`), the app's `MainActivity` must extend `FlutterFragmentActivity` (already configured in the project).

---

## How to Run

```bash
# Android emulator / device
flutter run

# Specific device
flutter run -d <device-id>
```

---

## How to Test

The project has **70 automated tests** across three categories. No device/emulator is needed — all tests use mocks and fake cubits.

### Unit tests (54 tests)

```bash
flutter test test/unit/
```

| Test file | Tests | What it covers |
|---|---|---|
| `task_filter_test.dart` | 18 | Status, priority, assignee, search, date-range filtering, apply, copyWith, activeCount |
| `session_cubit_test.dart` | 8 | checkSession (cached/empty/error), login (success/failure), logout, currentUser |
| `task_bloc_test.dart` | 5 | Load tasks (success/empty/error), filter by status/priority, delete |
| `validation_test.dart` | 23 | Email regex, password rules, title/description length, status/priority constants |

### Widget tests (6 tests)

```bash
flutter test test/widget/
```

| Test file | Tests | What it covers |
|---|---|---|
| `login_screen_test.dart` | 6 | Form renders, email required, invalid email, password required, short password, register link |

### Integration tests (10 tests)

```bash
flutter test test/integration/
```

| Test file | Tests | What it covers |
|---|---|---|
| `login_flow_test.dart` | 6 | Splash → login → home, credential validation, error messages |
| `project_task_flow_test.dart` | 4 | Project listing, task listing, bottom navigation, create/edit navigation |

### Run all tests at once

```bash
flutter test test/unit/ test/widget/ test/integration/
```

### Run with coverage

```bash
flutter test --coverage
```

---

## How to Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

The release APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## Test Credentials

All test accounts use the password `Password123!`.

### Organization A — Nimbus Digital (`org_a1b2c3`)

| Role | Email | Password |
|---|---|---|
| **Org Admin** | `ava.admin@nimbusdigital.test` | `Password123!` |
| Member | `marcus.member@nimbusdigital.test` | `Password123!` |
| Member | `priya.member@nimbusdigital.test` | `Password123!` |

### Organization B — Harborlight Studios (`org_d4e5f6`)

| Role | Email | Password |
|---|---|---|
| **Org Admin** | `daniel.admin@harborlightstudios.test` | `Password123!` |
| Member | `elena.member@harborlightstudios.test` | `Password123!` |

### Testing role-based behavior

1. **Admin flow**: Log in as `ava.admin@nimbusdigital.test` → create, edit, delete projects → assign tasks → manage members
2. **Member flow**: Log in as `marcus.member@nimbusdigital.test` → see projects (read-only) → create, edit tasks → cannot delete projects
3. **Cross-org isolation**: Log in as `daniel.admin@harborlightstudios.test` → see only Harborlight Studios projects, not Nimbus Digital
4. **Authorization enforcement**: As a member, an admin action (e.g., deleting a project) is blocked at the business-logic layer, not just hidden in the UI

---

## Screens

| Screen | Route | Description |
|---|---|---|
| **Splash** | `/` | App entry, session check, biometric prompt, auto-navigate |
| **Login** | `/login` | Email/password form with validation |
| **Register** | `/register` | Simulated registration with success dialog |
| **Home** | `/home` | Bottom nav: Projects / Inbox / Profile |
| **Project List** | `/home` (tab) | Org-scrolled projects with skeleton loading, pull-to-refresh |
| **Project Detail** | `/projects/:projectId` | Description, task summary, filterable task list, skeleton loading |
| **Project Form** | `/projects/form` | Create/edit project (admin only) |
| **Task Detail** | `/tasks/:taskId` | Full task view, status/assignee quick-change, comments, tags |
| **Task Form** | `/tasks/form` | Create/edit task with all fields |
| **Inbox** | `/home` (tab) | Notifications, tap to navigate to task |
| **Profile** | `/home` (tab) | User info, org, role, logout |
| **Settings** | `/settings` | Dark mode, biometric toggle, offline mode, error simulation guide |

### Shared widget library

| Widget | File | Purpose |
|---|---|---|
| `LoadingView` | `shared/widgets/loading_view.dart` | Centered spinner with optional message |
| `EmptyView` | `shared/widgets/empty_view.dart` | Icon + title + subtitle for empty states |
| `ErrorView` | `shared/widgets/error_view.dart` | Error message + retry button |
| `ConfirmDialog` | `shared/widgets/confirm_dialog.dart` | Destructive action confirmation |
| `StaleDataBanner` | `shared/widgets/stale_data_banner.dart` | Offline data warning banner |
| `SkeletonLoader` | `shared/widgets/skeleton_loader.dart` | Shimmer animation wrapper |
| `SkeletonBox` | same | Rounded rectangle placeholder |
| `SkeletonCircle` | same | Circle placeholder |
| `SkeletonProjectCard` | `shared/widgets/skeleton_project_card.dart` | Matches `ProjectCard` layout |
| `SkeletonTaskCard` | `shared/widgets/skeleton_task_card.dart` | Matches `TaskCard` layout |
| `AppAvatar` | `shared/widgets/app_avatar.dart` | Avatar with fallback initials |
| `AppButton` | `shared/widgets/app_button.dart` | Styled button variants |

---

## Known Limitations & Trade-offs

1. **In-memory mutations reset on cold restart**: `MockDatabase` re-seeds from the JSON asset on each app launch. Hive cache preserves the last-fetched state for offline reading, but any project/task created during a session is lost on restart. This is by design for a mock app — in production, mutations would persist to a real backend.

2. **Register is simulated**: The Register screen shows a success dialog but does not create a new user in the mock database or log the user in. The user must sign in with existing test credentials.

3. **No pending-operations queue for offline writes**: Offline writes are rejected outright with an error message rather than queued and synced. A local queue with reconciliation on reconnection would be more robust but adds significant complexity.

4. **No push notifications**: The notification list is a static mock from the JSON asset. Real-time notifications via FCM or similar are not implemented.

5. **Single-org per session**: Users cannot switch organizations. The org is determined at login by the test credential row.

6. **No request cancellation**: Data-layer operations don't support cancellation tokens. In a real backend integration, `CancelableOperation` or Dart `Completer` patterns would be used.

7. **Comments read from MockDatabase, not a dedicated repository**: Comments are loaded directly from `MockDatabase` rather than through a `CommentRepository`. This is a pragmatic shortcut — the comments UI works, but the architecture layer isn't as clean as it could be.

8. **Tablet layout not specifically optimized**: The UI uses responsive flex widgets and adapts to screen size, but there is no dedicated tablet/landscape layout (e.g., master-detail split view).

9. **No internationalization (i18n)**: All strings are hardcoded in English. Adding `flutter_localizations` + ARB files would be the standard approach.

10. **No golden tests or code coverage report**: The test suite covers functional logic but not visual regression (golden tests). Coverage reports can be generated with `flutter test --coverage` and viewed with `lcov`.
