import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:task_flow/core/router/auth_router_state.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';

/// Concrete [AuthRouterState] backed by [SessionCubit].
///
/// Lives in the auth feature because it is allowed to know about
/// [SessionCubit].  The core-layer [AppRouter] only sees the
/// [AuthRouterState] abstraction.
class AuthRouterStateImpl implements AuthRouterState {
  final SessionCubit _sessionCubit;
  late final _SessionCubitListenable _listenable;

  AuthRouterStateImpl(this._sessionCubit) {
    _listenable = _SessionCubitListenable(_sessionCubit);
  }

  // ─── AuthStatus mapping ──────────────────────────────────────────────────

  @override
  AuthStatus get status {
    final state = _sessionCubit.state;

    if (state is SessionInitial) return AuthStatus.initial;
    if (state is SessionLoading) return AuthStatus.loading;
    if (state is SessionAuthenticated) return AuthStatus.authenticated;
    if (state is SessionTokenExpired) return AuthStatus.tokenExpired;

    return AuthStatus.unauthenticated;
  }

  @override
  Listenable get listenable => _listenable;
}

// ─── Private ChangeNotifier adapter ─────────────────────────────────────────
// Bridges Bloc/Cubit's Stream to GoRouter's ChangeNotifier expectation.

class _SessionCubitListenable extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _SessionCubitListenable(SessionCubit cubit) {
    // Initial notification so GoRouter evaluates the redirect on first build.
    notifyListeners();

    _subscription = cubit.stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
