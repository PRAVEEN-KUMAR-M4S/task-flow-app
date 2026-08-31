import 'package:flutter/foundation.dart';

/// Auth status values the router needs to decide navigation.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  tokenExpired,
}

/// Abstract contract the router depends on.
///
/// Lives in [core/router] so the router never imports a feature's
/// presentation layer.  The concrete implementation lives in
/// `features/auth/presentation/` and maps [SessionState] → [AuthStatus].
abstract class AuthRouterState {
  /// Current auth status derived from the session.
  AuthStatus get status;

  /// A [Listenable] that fires whenever [status] may have changed.
  /// GoRouter uses this via [GoRouter.refreshListenable].
  Listenable get listenable;
}
