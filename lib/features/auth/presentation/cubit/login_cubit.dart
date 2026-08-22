import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';

// ─── State ────────────────────────────────────────────────────────────────────

abstract class LoginState extends Equatable {
  const LoginState();
  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  const LoginSuccess();
}

class LoginFailure extends LoginState {
  final String message;
  const LoginFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

/// Manages the login form's UI state.
/// Delegates actual auth to [SessionCubit].
class LoginCubit extends Cubit<LoginState> {
  final SessionCubit _sessionCubit;

  LoginCubit({required SessionCubit sessionCubit})
      : _sessionCubit = sessionCubit,
        super(const LoginInitial());

  Future<void> login({required String email, required String password}) async {
    emit(const LoginLoading());
    final error = await _sessionCubit.login(email: email, password: password);
    // The navigation triggered by SessionCubit may have already closed this
    // cubit before the await returns, so guard every post-await emit.
    if (isClosed) return;
    if (error == null) {
      emit(const LoginSuccess());
    } else {
      emit(LoginFailure(error));
    }
  }

  void reset() => emit(const LoginInitial());
}
