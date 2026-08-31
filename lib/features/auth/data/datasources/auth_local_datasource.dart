import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/mock/error_simulator.dart';
import 'package:task_flow/core/mock/mock_database.dart';
import 'package:task_flow/core/network/mock_datasource_mixin.dart';
import 'package:task_flow/core/storage/secure_storage_service.dart';
import 'package:task_flow/features/auth/data/models/auth_response_model.dart';
import 'package:task_flow/features/auth/data/models/test_credential_model.dart';
import 'package:task_flow/features/auth/data/models/user_model.dart';

// ─── Abstract ─────────────────────────────────────────────────────────────────

abstract class AuthLocalDatasource {
  Future<({UserModel user, AuthResponseModel token})> login({
    required String email,
    required String password,
  });

  Future<AuthResponseModel> refreshToken(String refreshToken);

  Future<UserModel?> getCachedUser();

  /// The demo logins shipped in the mock data, for the login screen to display.
  Future<List<TestCredentialModel>> getTestCredentials();
}

// ─── Implementation ───────────────────────────────────────────────────────────

class AuthLocalDatasourceImpl
    with MockDatasourceMixin
    implements AuthLocalDatasource {
  final SecureStorageService _secureStorage;
  final MockDatabase _db;

  @override
  final ErrorSimulator errorSimulator;

  AuthLocalDatasourceImpl({
    required SecureStorageService secureStorage,
    required MockDatabase database,
    required this.errorSimulator,
  }) : _secureStorage = secureStorage,
       _db = database;

  // ─── Login ──────────────────────────────────────────────────────────────

  @override
  Future<({UserModel user, AuthResponseModel token})> login({
    required String email,
    required String password,
  }) async {
    await _db.ensureLoaded();
    await simulatedDelay();

    final normalizedEmail = email.trim().toLowerCase();
    final credential = _db.testCredentials.firstWhere(
      (row) =>
          (row['email'] as String?)?.trim().toLowerCase() == normalizedEmail &&
          row['password'] == password,
      orElse: () => const <String, dynamic>{},
    );

    if (credential.isEmpty) {
      throw const InvalidCredentialsException();
    }

    final orgId = credential['org_id'] as String;

    // `test_credentials` has no `user_id`, so the account is resolved by the
    // e-mail address it shares with the `users` table.
    final userJson = _db.users.values.firstWhere(
      (row) =>
          (row['email'] as String?)?.trim().toLowerCase() == normalizedEmail,
      orElse: () => throw ServerException(
        message: 'No user in the mock data matches "$email".',
      ),
    );
    final userId = userJson['id'] as String;

    // The credential row states a role, but `org_members` is authoritative.
    final membership = _db.membership(orgId: orgId, userId: userId);
    if (membership == null) {
      throw UnauthorizedException(
        message: 'This account is not a member of organization "$orgId".',
      );
    }

    final userModel = UserModel.fromJson(userJson).withOrgMembership(
      orgId: orgId,
      orgName: _orgName(orgId),
      role: membership['role'] as String,
    );

    return (
      user: userModel,
      token: AuthResponseModel.fromJson(_db.mockLoginResponse),
    );
  }

  // ─── Refresh Token ──────────────────────────────────────────────────────

  @override
  Future<AuthResponseModel> refreshToken(String refreshToken) async {
    await _db.ensureLoaded();
    await simulatedDelay();

    if (refreshToken.isEmpty) {
      throw const UnauthorizedException(message: 'Missing refresh token.');
    }

    final stored = await _secureStorage.getRefreshToken();
    if (stored == null || stored != refreshToken) {
      throw const UnauthorizedException(
        message: 'Refresh token is no longer valid. Please sign in again.',
      );
    }

    // A real backend would mint a new pair; the mock reissues the canned one,
    // and `toEntity()` stamps a fres ehxpiry relative to now.
    return AuthResponseModel.fromJson(_db.mockLoginResponse);
  }

  // ─── Get Cached User ────────────────────────────────────────────────────

  @override
  Future<UserModel?> getCachedUser() async {
    final userId = await _secureStorage.getUserId();
    final orgId = await _secureStorage.getOrgId();
    if (userId == null || orgId == null) return null;

    // Access token is still valid — return user directly.
    if (await _secureStorage.hasValidSession()) {
      return _loadUser(userId, orgId);
    }

    // Access token expired — attempt silent refresh.

    return _tryRefreshAndReturnUser(userId, orgId);
  }

  /// Load the user from mock data (token is valid).
  Future<UserModel?> _loadUser(String userId, String orgId) async {
    await _db.ensureLoaded();

    final userJson = _db.users[userId];
    if (userJson == null) return null;

    final membership = _db.membership(orgId: orgId, userId: userId);
    if (membership == null) return null;

    return UserModel.fromJson(userJson).withOrgMembership(
      orgId: orgId,
      orgName: _orgName(orgId),
      role: membership['role'] as String,
    );
  }

  /// Try to refresh the access token silently and return the user.
  Future<UserModel?> _tryRefreshAndReturnUser(
    String userId,
    String orgId,
  ) async {
    final storedRefreshToken = await _secureStorage.getRefreshToken();
    if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
      return null;
    }

    try {
      final model = await refreshToken(storedRefreshToken);
      final token = model.toEntity();

      await _secureStorage.updateAccessToken(
        accessToken: token.accessToken,
        expiresAt: token.expiresAt,
        refreshToken: token.refreshToken,
      );

      return _loadUser(userId, orgId);
    } catch (e) {
      // Refresh failed — user must log in again.
      return null;
    }
  }

  // ─── Test Credentials ───────────────────────────────────────────────────

  @override
  Future<List<TestCredentialModel>> getTestCredentials() async {
    await _db.ensureLoaded();
    return _db.testCredentials.map(TestCredentialModel.fromJson).toList();
  }

  String _orgName(String orgId) =>
      (_db.organizations[orgId]?['name'] as String?) ?? orgId;
}
