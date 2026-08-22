import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum ConnectivityStatus { online, offline }

class ConnectivityState extends Equatable {
  final ConnectivityStatus status;

  const ConnectivityState({required this.status});

  bool get isOnline => status == ConnectivityStatus.online;
  bool get isOffline => status == ConnectivityStatus.offline;

  const ConnectivityState.online()
      : status = ConnectivityStatus.online;

  const ConnectivityState.offline()
      : status = ConnectivityStatus.offline;

  @override
  List<Object> get props => [status];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

/// Simulated connectivity cubit.
///
/// Since there is no real network in this assignment, connectivity is toggled
/// manually via the Settings screen debug menu.
/// Real connectivity_plus detection is omitted per the spec — it would only
/// feed this same toggle in production.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit() : super(const ConnectivityState.online());

  /// Toggle between online and offline for demo purposes.
  void toggle() {
    if (state.isOnline) {
      emit(const ConnectivityState.offline());
    } else {
      emit(const ConnectivityState.online());
    }
  }

  void setOnline() => emit(const ConnectivityState.online());
  void setOffline() => emit(const ConnectivityState.offline());
}
