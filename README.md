# TaskFlow — Project Management App

A Flutter project management application built with clean architecture, Bloc/Cubit state management, and a fully mocked data layer. Designed as a demonstration of scalable Flutter patterns — no real network calls, all data served from a local mock JSON asset.

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

**TaskFlow** is a task and project management app for organizations. Users belong to an organization and can be either `org_admin` or `member`. Admins can create/edit/delete projects; members can manage tasks within their assigned projects.

All data is served from a single `assets/mock_data/mock-data.json` file parsed through a data-source layer. The app simulates real-world backend behaviors including token expiry, token refresh, network errors, offline mode, and artificial latency.

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

### Key principles:

- **Domain layer** defines entities (`Project`, `TaskEntity`, `User`, `AuthToken`) and repository interfaces. No Flutter or platform dependencies.
- **Data layer** implements those interfaces. Datasources read/write mock JSON. Models handle JSON serialization with `json_serializable`. This layer is the only place that touches the asset file.
- **Presentation layer** contains screens (widgets), Cubits/Blocs (state), and nothing else. No `rootBundle.loadString`, no direct JSON access.
- **Dependency injection** via `get_it` wires everything together at startup.

### Cross-cutting concerns live in `core/`:

| Module | Responsibility |
|---|---|
| `core/constants/` | Route names, storage keys, simulation config, error-trigger tokens |
| `core/di/` | `get_it` service locator setup |
| `core/error/` | `Failure` hierarchy, `Exception` types, `failure_mapper` |
| `core/mock/` | `MockDatabase` (in-memory DB seeded from asset), `ErrorSimulator` (debug toggle) |
| `core/network/` | `ConnectivityCubit` (offline toggle), `MockDatasourceMixin` (simulated delay + error checking) |
| `core/router/` | `GoRouter` config with auth redirect guard |
| `core/storage/` | `SecureStorageService` (tokens via `flutter_secure_storage`), `HiveService` (offline cache) |
| `core/theme/` | `AppTheme` (light/dark), `ThemeCubit` |
| `core/usecase/` | Base `UseCase` and `UseCaseNoParams` abstract classes |
| `core/utils/` | `Cached<T>` wrapper, `Either` extensions |

---

## Folder Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── di/
│   │   └── injection_container.dart
│   ├── error/
│   │   ├── exceptions.dart
│   │   ├── failures.dart
│   │   └── failure_mapper.dart
│   ├── mock/
│   │   ├── mock_database.dart
│   │   └── error_simulator.dart
│   ├── network/
│   │   ├── connectivity_cubit.dart
│   │   └── mock_datasource_mixin.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── storage/
│   │   ├── secure_storage_service.dart
│   │   └── hive_service.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── theme_cubit.dart
│   ├── usecase/
│   │   └── usecase.dart
│   └── utils/
│       ├── cached.dart
│       └── either_extensions.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/auth_local_datasource.dart
│   │   │   ├── models/  (auth_response_model, user_model, test_credential_model)
│   │   │   └── repositories/auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/  (auth_token, user, test_credential)
│   │   │   ├── repositories/auth_repository.dart
│   │   │   ├── services/authorization_service.dart
│   │   │   └── usecases/  (login, logout, refresh_token, get_cached_session)
│   │   └── presentation/
│   │       ├── cubit/  (session_cubit, login_cubit)
│   │       ├── screens/  (splash, login, register)
│   │       └── widgets/  (auth_text_field)
│   ├── projects/
│   │   ├── data/  (datasources, models, repositories)
│   │   ├── domain/  (entities, repositories, usecases)
│   │   └── presentation/
│   │       ├── cubit/  (project_list_cubit, project_detail_cubit)
│   │       ├── screens/  (project_list, project_detail, project_form)
│   │       └── widgets/  (project_card, task_summary_row)
│   ├── tasks/
│   │   ├── data/  (datasources, models, repositories)
│   │   ├── domain/  (entities, repositories, usecases)
│   │   └── presentation/
│   │       ├── bloc/task_bloc.dart
│   │       ├── cubit/task_detail_cubit.dart
│   │       ├── screens/  (task_detail, task_form)
│   │       └── widgets/  (task_card, task_filter_bar, assignee_picker, status_chip, priority_badge)
│   ├── users/
│   │   ├── data/  (datasources, models, repositories)
│   │   └── domain/  (entities, repositories, usecases)
│   ├── notifications/
│   │   ├── data/  (datasources, models, repositories)
│   │   ├── domain/  (entities, repositories, usecases)
│   │   └── presentation/  (cubit, screen, widgets)
│   ├── home/
│   │   └── presentation/screens/home_screen.dart
│   ├── profile/
│   │   └── presentation/screens/profile_screen.dart
│   └── settings/
│       └── presentation/screens/settings_screen.dart
└── shared/
    └── widgets/  (app_avatar, app_button, confirm_dialog, empty_view, error_view, loading_view, stale_data_banner)
```

---

## State Management

The app uses **flutter_bloc** (Bloc/Cubit pattern) consistently across all features.

### State hierarchy pattern

Every feature follows the same lifecycle states:

```
Initial → Loading → Success / Empty / Error
```

Additional states used where appropriate:

| Feature | States |
|---|---|
| **Session** | `SessionInitial`, `SessionLoading`, `SessionAuthenticated`, `SessionUnauthenticated`, `SessionTokenExpired`, `SessionBiometricRequired` |
| **Login** | `LoginInitial`, `LoginLoading`, `LoginSuccess`, `LoginFailure` |
| **Project List** | `ProjectListInitial`, `ProjectListLoading`, `ProjectListSuccess`, `ProjectListEmpty`, `ProjectListError`, `ProjectMutationLoading` |
| **Project Detail** | `ProjectDetailLoading`, `ProjectDetailSuccess`, `ProjectDetailError` |
| **Tasks** | `TaskInitial`, `TaskLoading`, `TaskSuccess`, `TaskEmpty`, `TaskError` |
| **Task Detail** | `TaskDetailLoading`, `TaskDetailSuccess`, `TaskDetailError` |
| **Notifications** | `NotificationInitial`, `NotificationLoading`, `NotificationSuccess`, `NotificationEmpty`, `NotificationError` |

### Which feature uses Bloc vs Cubit:

- **Bloc** (events + states): `TaskBloc` — complex multi-operation task management with concurrent filter/mutation events.
- **Cubit** (state-only): `SessionCubit`, `LoginCubit`, `ProjectListCubit`, `ProjectDetailCubit`, `TaskDetailCubit`, `NotificationCubit`, `ThemeCubit`, `ConnectivityCubit` — simpler state transitions.

### Navigation state management:

`GoRouter` is wired to `SessionCubit.stream` via `refreshListenable`, so route redirects react automatically to auth state changes (login → home, logout → login).

---

## Mock Data Layer

### How it works

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

### MockDatabase

`MockDatabase` (in `core/mock/mock_database.dart`) is an in-memory, mutable stand-in for a remote database. It:

1. Loads and parses the JSON asset **once** via `ensureLoaded()` (uses `compute()` for off-main-isolate parsing).
2. Seeds in-memory tables (`organizations`, `users`, `projects`, `tasks`, `comments`, `notifications`, `orgMembers`).
3. All datasources read/write through this single instance — so creating a task through one feature is immediately visible to another.

### Data flow

```
JSON Asset → MockDatabase (in-memory) → LocalDatasource (with simulated delay)
         → Repository (with Cached<T> wrapper + offline fallback)
         → UseCase → Cubit/Bloc → Screen
```

### Simulated network delay

Every datasource operation passes through `MockDatasourceMixin.simulatedDelay()` which adds:
- **Base delay**: 300ms
- **Random jitter**: 0–500ms
- **Total**: 300–800ms

This makes loading states observable and realistic.

### Offline caching

Repositories use a `Cached<T>` wrapper to distinguish fresh vs stale data:

- **Online**: Datasource reads from `MockDatabase`, result wrapped as `Cached.fresh(data)`.
- **Offline**: Repository reads from Hive cache, result wrapped as `Cached.stale(data)`.
- The UI shows a `StaleDataBanner` when displaying cached data.
- Writes are **rejected** offline with a clear error message ("You need to be online to create a project").

---

## Authentication & Token Flow

### Login flow

1. User enters email + password on `LoginScreen`.
2. `LoginCubit` delegates to `SessionCubit.login()`.
3. `SessionCubit` calls `LoginUseCase` → `AuthRepository.login()`.
4. `AuthRepositoryImpl` calls `AuthLocalDatasource.login()`:
   - Loads `MockDatabase`, finds matching `test_credentials` row.
   - Resolves the user from the `users` table.
   - Verifies org membership via `org_members`.
   - Returns the `mock_login_response` token payload.
5. `AuthRepositoryImpl` persists to `SecureStorageService`:
   - `access_token`, `refresh_token`, `user_id`, `org_id`, `token_expiry`.
6. `SessionCubit` emits `SessionAuthenticated(user)` and starts the expiry timer.

### Token expiry & refresh

The access token expires after **900 seconds (15 minutes)**, as configured by `access_token_expires_in_seconds` in the mock data.

**Timer-based refresh:**
1. On login, `SessionCubit._startExpiryTimer()` reads the stored `expiresAt` timestamp.
2. It schedules a `Timer` to fire just before expiry.
3. When the timer fires, `_onTokenExpiry()` calls `RefreshTokenUseCase`.
4. The datasource validates the refresh token, reissues the canned token pair, and `toEntity()` stamps a fresh `expiresAt`.
5. New tokens are saved to secure storage, and the timer restarts.

**App-relaunch refresh:**
1. `SplashScreen` calls `SessionCubit.checkSession()`.
2. `GetCachedSessionUseCase` → `AuthRepository.getCachedUser()`.
3. `AuthLocalDatasource.getCachedUser()` checks if the access token is still valid.
4. If **expired**, it silently attempts a refresh using the stored refresh token.
5. On success: new tokens saved, user returned — **no re-login required**.
6. On failure (refresh token also expired): returns `null` → user must log in.

### Token lifetimes

| Token | Lifetime | Mock value |
|---|---|---|
| Access token | 15 minutes | `access_token_expires_in_seconds: 900` |
| Refresh token | 7 days | `refresh_token_expires_in_seconds: 604800` |

### Logout

`SessionCubit.logout()` → `LogoutUseCase` → clears all secure storage keys → emits `SessionUnauthenticated` → router redirects to `/login`.

### Biometric unlock (bonus)

The app includes a `BiometricService` for optional biometric (fingerprint/face) unlock of an existing session. When enabled (default: on if available), the splash screen prompts for biometrics after detecting a valid cached session.

---

## Simulated Error & Offline States

There are **three ways** to trigger error states in the app:

### Method 1: Error-trigger substrings (data-driven)

The `MockDatasourceMixin.checkForSimulatedError()` method scans IDs, names, and titles for specific substrings. Any project/task containing these triggers the corresponding error:

| Substring | Error thrown | How to trigger |
|---|---|---|
| `err404` | `NotFoundException` (simulated 404) | Create a task named "Test err404 task" |
| `errTimeout` | `TimeoutException` (simulated timeout) | Create a project named "Report errTimeout" |
| `errValidation` | `ValidationException` (simulated validation) | Create a task with title containing "errValidation" |

You can also **deep link** to a synthetic ID: navigate to `/tasks/task_err404` or `/projects/proj_errTimeout`.

### Method 2: Settings → Debug & Simulation

**Error Simulator** (Settings screen): A debug toggle that forces the next data-layer read/write to fail. Currently available error modes are displayed in the Settings screen under "Debug & Simulation".

**Offline Mode** (Settings screen): A toggle that switches `ConnectivityCubit` between online and offline. When offline:
- Repositories serve cached Hive data (wrapped as `Stale`).
- A `StaleDataBanner` appears at the top of list screens.
- Write operations (create/edit/delete) are rejected with an error message.
- The user can retry when back online.

### Method 3: Real device behavior

On a real device, the `connectivity_plus` package detects actual network status. Since this is a mock app, the toggle is manual.

---

## Local Setup

### Prerequisites

- **Flutter SDK**: `>= 3.10.4` (as specified in `pubspec.yaml`)
- **Dart SDK**: `>= 3.10.4`
- **Android Studio** or **VS Code** with Flutter extension
- **Chrome** (for web target) or an Android emulator / iOS simulator

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd task_flow

# Install dependencies
flutter pub get

# (Optional) Generate model code if .g.dart files need regeneration
dart run build_runner build --delete-conflicting-outputs
```

---

## How to Run

```bash
# Android emulator / device
flutter run

# Chrome (web)
flutter run -d chrome

# Windows desktop
flutter run -d windows
```

---

## How to Test

```bash
# Run all unit and widget tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests (if available)
flutter test integration_test/
```

> **Note:** The current test suite is minimal. A full test suite covering auth logic, task filtering, form validation, and widget states is recommended before submission.

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

1. **Admin flow**: Log in as `ava.admin@nimbusdigital.test` → create, edit, delete projects → assign tasks.
2. **Member flow**: Log in as `marcus.member@nimbusdigital.test` → see projects (read-only) → create, edit tasks → cannot delete projects.
3. **Cross-org isolation**: Log in as `daniel.admin@harborlightstudios.test` → see only Harborlight Studios projects, not Nimbus Digital.
4. **Deep-link admin block**: As a member, try navigating directly to a project's delete action — the `AuthorizationService` blocks it at the business logic layer.

---

## Screens

| Screen | Route | Description |
|---|---|---|
| **Splash** | `/` | App entry, checks cached session, routes to home or login |
| **Login** | `/login` | Email/password form, validates against mock credentials |
| **Register** | `/register` | Simulated registration (no persistence, success dialog) |
| **Home** | `/home` | Bottom nav: Projects / Inbox / Profile |
| **Project List** | `/home` (tab) | Org-scrolled projects, pull-to-refresh, create (admin) |
| **Project Detail** | `/projects/:projectId` | Description, task summary, task list, add task |
| **Project Form** | `/projects/form` | Create/edit project (admin only) |
| **Task Detail** | `/tasks/:taskId` | Full task view, status/assignee quick-change, comments |
| **Task Form** | `/tasks/form` | Create/edit task with all fields |
| **Inbox** | `/home` (tab) | Notifications, tap to navigate to task |
| **Profile** | `/home` (tab) | User info, org, role, logout button |
| **Settings** | `/settings` | Dark mode toggle, offline mode, error trigger guide, about |

---

## Known Limitations & Trade-offs

1. **Biometric service file missing**: `biometric_service.dart` is referenced but not present on disk. The biometric unlock feature will not compile until this file is created or the references are removed.

2. **Comments loaded directly from JSON**: `TaskDetailScreen` currently reads comments via `rootBundle.loadString()` rather than through the data layer. This violates the architecture rule but keeps comments functional. A proper `CommentDatasource` → `CommentRepository` path should replace this.

3. **Task list is embedded in Project Details**: There is no standalone "Task List" screen. Tasks are only accessible from within a project. A global task list filtered by user could be added.

4. **No pending-operations queue**: Offline writes are rejected outright rather than queued and synced. A local queue with reconciliation would be more robust.

5. **No request cancellation**: API-equivalent operations don't support cancellation tokens. In a real backend integration, `CancelableOperation` or Dart `Completer` patterns would be used.

6. **Test coverage is minimal**: The `test/` directory contains only the default Flutter template. Full unit, widget, and integration tests need to be written.

7. **In-memory mutations are not persisted across app restarts**: Project/task edits survive within a session (stored in `MockDatabase` and Hive cache) but the `MockDatabase` re-seeds from the asset on each cold start. Hive cache provides offline persistence for the last-fetched state.

8. **Register screen is simulated**: Registration shows a success dialog but does not create a new user in the mock database or log the user in. The user must sign in with existing test credentials.

9. **No push notifications**: The notification list is a static mock from the JSON asset. Real-time notifications via FCM or similar are not implemented.

10. **Single-org per session**: Users cannot switch organizations. The org is determined at login by the test credential row.
