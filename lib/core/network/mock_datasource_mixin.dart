import 'dart:math';

import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/mock/error_simulator.dart';

/// Mixin applied to mock data sources to add:
/// - artificial network latency,
/// - the Settings-driven forced-error switch,
/// - error-trigger substring detection on ids and free-text fields.
mixin MockDatasourceMixin {
  static final Random _random = Random();

  /// The debug switch consulted by [simulatedDelay]. Data sources receive it
  /// through their constructor and expose it here.
  ErrorSimulator get errorSimulator;

  /// Simulates artificial network latency, then applies any armed debug error.
  ///
  /// Every data-source operation awaits this first, so a single armed error
  /// reliably surfaces on the next request regardless of which feature made it.
  Future<void> simulatedDelay() async {
    final ms = AppConstants.simulatedDelayBaseMs +
        _random.nextInt(AppConstants.simulatedDelayJitterMs + 1);
    await Future<void>.delayed(Duration(milliseconds: ms));
    errorSimulator.maybeThrow();
  }

  /// Throws the matching exception when any of [values] contains an
  /// error-trigger substring.
  ///
  /// Pass ids as well as user-supplied names/titles: the shipped mock data has
  /// no trigger ids, so naming a project "Launch errTimeout" is the only
  /// data-driven way to reach these states without a deep link.
  void checkForSimulatedError(String? value, [String? extra]) {
    for (final candidate in [value, extra]) {
      if (candidate == null || candidate.isEmpty) continue;
      if (candidate.contains(AppConstants.errIdPrefix404)) {
        throw const NotFoundException(
          message: 'Simulated 404: the requested resource does not exist.',
        );
      }
      if (candidate.contains(AppConstants.errIdPrefixTimeout)) {
        throw const TimeoutException(
          message: 'Simulated timeout: the request took too long to complete.',
        );
      }
      if (candidate.contains(AppConstants.errIdPrefixValidation)) {
        throw const ValidationException(
          message: 'Simulated validation error: the data does not meet '
              'the server requirements.',
        );
      }
    }
  }
}
