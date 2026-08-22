import 'package:equatable/equatable.dart';
import 'package:task_flow/core/constants/app_constants.dart';

/// A demo login shipped in `auth_mock.test_credentials`.
///
/// Exposed as a domain entity so the login screen can render the demo logins
/// without hardcoding them in the widget tree — the assignment requires them to
/// be loaded through the data layer. The password is used only to prefill the
/// form; it is never written to secure storage or any cache.
class TestCredential extends Equatable {
  final String email;
  final String password;
  final String orgId;
  final String role;

  const TestCredential({
    required this.email,
    required this.password,
    required this.orgId,
    required this.role,
  });

  bool get isAdmin => role == AppConstants.roleOrgAdmin;

  String get roleLabel => isAdmin ? 'Org Admin' : 'Member';

  @override
  List<Object?> get props => [email, password, orgId, role];

  /// Omits the password so a stray log line cannot leak it.
  @override
  String toString() => 'TestCredential($email, $orgId, $role)';
}
