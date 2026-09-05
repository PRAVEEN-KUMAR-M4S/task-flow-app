import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
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

/// Manages connectivity state by listening to the real [Connectivity] stream.
///
/// A manual override (via the Settings debug toggle) can force the app into
/// online or offline mode regardless of actual network conditions. Once the
/// override is cleared the cubit resumes following the real connectivity
/// stream.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _manualOverride = false;

  ConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(const ConnectivityState.online()) {
    _listenToConnectivity();
  }

  /// Subscribe to the platform connectivity stream and update state.
  void _listenToConnectivity() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (_manualOverride) return; // debug toggle is active — ignore real changes
      final connected = results.any((r) => r != ConnectivityResult.none);
      emit(connected
          ? const ConnectivityState.online()
          : const ConnectivityState.offline());
    });
  }

  // ── Manual override (Settings debug toggle) ────────────────────────────────

  /// Force offline regardless of real connectivity.
  void setOffline() {
    _manualOverride = true;
    emit(const ConnectivityState.offline());
  }

  /// Force online regardless of real connectivity.
  void setOnline() {
    _manualOverride = true;
    emit(const ConnectivityState.online());
  }

  /// Clear any manual override and resume following real connectivity.
  void clearOverride() {
    _manualOverride = false;
    // Immediately re-check real connectivity.
    _connectivity.checkConnectivity().then((results) {
      if (isClosed || _manualOverride) return;
      final connected = results.any((r) => r != ConnectivityResult.none);
      emit(connected
          ? const ConnectivityState.online()
          : const ConnectivityState.offline());
    });
  }

  bool get isManualOverride => _manualOverride;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
