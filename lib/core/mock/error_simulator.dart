import 'package:flutter/foundation.dart';
import 'package:task_flow/core/error/exceptions.dart';

/// The error kinds the mock data layer can be asked to produce on demand.
enum SimulatedError {
  none,
  notFound,
  timeout,
  validation,
  network;

  String get label => switch (this) {
        SimulatedError.none => 'None (normal responses)',
        SimulatedError.notFound => '404 — Not found',
        SimulatedError.timeout => 'Timeout',
        SimulatedError.validation => 'Validation error',
        SimulatedError.network => 'Network unavailable',
      };
}

/// Debug switch that forces the next data-layer read/write to fail.
///
/// The assignment requires the simulated 404 / timeout / validation states to
/// be reachable *deterministically*. The mock data ships no error-trigger ids,
/// so this switch (surfaced in Settings → Debug & Simulation) is the primary
/// way to demonstrate them; the id/name substring triggers in
/// [MockDatasourceMixin] remain available as a second route.
///
/// Held in `core` rather than a feature so every data source can consult it
/// without depending on the presentation layer.
class ErrorSimulator extends ChangeNotifier {
  SimulatedError _mode = SimulatedError.none;

  /// When true the forced error fires once and then resets itself.
  bool _oneShot = true;

  SimulatedError get mode => _mode;
  bool get oneShot => _oneShot;
  bool get isArmed => _mode != SimulatedError.none;

  void arm(SimulatedError mode, {bool oneShot = true}) {
    if (_mode == mode && _oneShot == oneShot) return;
    _mode = mode;
    _oneShot = oneShot;
    notifyListeners();
  }

  void disarm() => arm(SimulatedError.none);

  /// Throws the armed exception, if any. Data sources call this at the start of
  /// every operation.
  void maybeThrow() {
    final mode = _mode;
    if (mode == SimulatedError.none) return;
    if (_oneShot) {
      _mode = SimulatedError.none;
      notifyListeners();
    }
    switch (mode) {
      case SimulatedError.notFound:
        throw const NotFoundException(
          message: 'Simulated 404: the requested resource does not exist.',
        );
      case SimulatedError.timeout:
        throw const TimeoutException(
          message: 'Simulated timeout: the request took too long to complete.',
        );
      case SimulatedError.validation:
        throw const ValidationException(
          message: 'Simulated validation error: the server rejected this data.',
        );
      case SimulatedError.network:
        throw const NetworkException(
          message: 'Simulated network error: unable to reach the server.',
        );
      case SimulatedError.none:
        return;
    }
  }
}
