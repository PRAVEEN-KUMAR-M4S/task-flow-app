import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/core/storage/secure_storage_service.dart';
import 'package:task_flow/features/auth/domain/entities/user.dart';
import 'package:task_flow/features/auth/domain/usecases/get_cached_session_usecase.dart';
import 'package:task_flow/features/auth/domain/usecases/login_usecase.dart';
import 'package:task_flow/features/auth/domain/usecases/logout_usecase.dart';
import 'package:task_flow/features/auth/domain/usecases/refresh_token_usecase.dart';

// ─── State ─────────────────────────────────────────────────────────────────────

abstract class SessionState extends Equatable {
  const SessionState();
  @override
  List<Object?> get props => [];
}

class SessionInitial extends SessionState {
  const SessionInitial();
}

class SessionLoading extends SessionState {
  const SessionLoading();
}

class SessionAuthenticated extends SessionState {
  final User user;
  const SessionAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

class SessionTokenExpired extends SessionState {
  const SessionTokenExpired();
}

// ─── Cubit ──────────────────────────────────────────────────────────────────────

/// App-scoped cubit. Provided above the router so the route guard can read it.
/// Manages session lifecycle: authentication, token refresh, and expiry.
class SessionCubit extends Cubit<SessionState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final RefreshTokenUseCase _refreshTokenUseCase;
  final GetCachedSessionUseCase _getCachedSessionUseCase;
  final SecureStorageService _secureStorage;

  Timer? _expiryTimer;

  SessionCubit({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required RefreshTokenUseCase refreshTokenUseCase,
    required GetCachedSessionUseCase getCachedSessionUseCase,
    required SecureStorageService secureStorage,
  }) : _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _refreshTokenUseCase = refreshTokenUseCase,
       _getCachedSessionUseCase = getCachedSessionUseCase,
       _secureStorage = secureStorage,
       super(const SessionInitial());

  // ─── Check Existing Session ───────────────────────────────────────────────

  Future<void> checkSession() async {
    emit(const SessionLoading());
    final result = await _getCachedSessionUseCase();
    result.fold((failure) => emit(const SessionUnauthenticated()), (user) {
      if (user != null) {
        emit(SessionAuthenticated(user));
        _startExpiryTimer();
      } else {
        emit(const SessionUnauthenticated());
      }
    });
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    emit(const SessionLoading());
    final result = await _loginUseCase(
      LoginParams(email: email, password: password),
    );
    return result.fold(
      (failure) {
        emit(const SessionUnauthenticated());
        return failure.message;
      },
      (user) {
        emit(SessionAuthenticated(user));
        _startExpiryTimer();
        return null; // null = success
      },
    );
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _cancelTimer();
    await _logoutUseCase();
    emit(const SessionUnauthenticated());
  }

  // ─── Token Expiry Timer ───────────────────────────────────────────────────

  void _startExpiryTimer() {
    _cancelTimer();
    _scheduleExpiryFromStorage();
  }

  /// Read the actual expiry from storage and schedule the timer accordingly.
  Future<void> _scheduleExpiryFromStorage() async {
    final expiresAt = await _secureStorage.getTokenExpiry();
    if (expiresAt == null) {
      _expiryTimer = Timer(
        const Duration(seconds: AppConstants.fallbackTokenExpirySeconds),
        _onTokenExpiry,
      );
      return;
    }

    final now = DateTime.now();
    final remaining = expiresAt.difference(now);
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      // Already expired — refresh immediately.
      _onTokenExpiry();
    } else {
      _expiryTimer = Timer(remaining, _onTokenExpiry);
    }
  }

  void _cancelTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }

  Future<void> _onTokenExpiry() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) {
      emit(const SessionTokenExpired());
      return;
    }

    final result = await _refreshTokenUseCase(NoParams());
    if (isClosed) return;
    result.fold(
      (failure) {
        // Refresh failed → force logout
        emit(const SessionTokenExpired());
      },
      (_) {
        // Refresh succeeded → restart timer
        _startExpiryTimer();
      },
    );
  }

  /// Returns current authenticated user or null.
  User? get currentUser {
    final s = state;
    if (s is SessionAuthenticated) return s.user;
    return null;
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
