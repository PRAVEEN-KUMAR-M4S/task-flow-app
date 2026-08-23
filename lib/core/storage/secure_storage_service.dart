import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/core/error/exceptions.dart';

/// Wrapper around [FlutterSecureStorage] providing typed read/write
/// for session tokens and user identity.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  // ─── Write ──────────────────────────────────────────────────────────────

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String orgId,
    required DateTime expiresAt,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: AppConstants.storageAccessToken, value: accessToken),
        _storage.write(key: AppConstants.storageRefreshToken, value: refreshToken),
        _storage.write(key: AppConstants.storageUserId, value: userId),
        _storage.write(key: AppConstants.storageOrgId, value: orgId),
        _storage.write(
            key: AppConstants.storageTokenExpiry,
            value: expiresAt.toIso8601String()),
      ]);
    } catch (e) {
      throw const CacheException(message: 'Failed to save session to secure storage.');
    }
  }

  Future<void> updateAccessToken({
    required String accessToken,
    required DateTime expiresAt,
    String? refreshToken,
  }) async {
    try {
      final futures = [
        _storage.write(key: AppConstants.storageAccessToken, value: accessToken),
        _storage.write(
            key: AppConstants.storageTokenExpiry,
            value: expiresAt.toIso8601String()),
      ];
      if (refreshToken != null) {
        futures.add(
          _storage.write(key: AppConstants.storageRefreshToken, value: refreshToken),
        );
      }
      await Future.wait(futures);
    } catch (e) {
      throw const CacheException(message: 'Failed to update access token.');
    }
  }

  // ─── Read ───────────────────────────────────────────────────────────────

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.storageAccessToken);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.storageRefreshToken);

  Future<String?> getUserId() =>
      _storage.read(key: AppConstants.storageUserId);

  Future<String?> getOrgId() =>
      _storage.read(key: AppConstants.storageOrgId);

  Future<DateTime?> getTokenExpiry() async {
    final raw = await _storage.read(key: AppConstants.storageTokenExpiry);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    final expiry = await getTokenExpiry();
    if (token == null || expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  // ─── Clear ──────────────────────────────────────────────────────────────

  Future<void> clearSession() async {
    try {
      await Future.wait([
        _storage.delete(key: AppConstants.storageAccessToken),
        _storage.delete(key: AppConstants.storageRefreshToken),
        _storage.delete(key: AppConstants.storageUserId),
        _storage.delete(key: AppConstants.storageOrgId),
        _storage.delete(key: AppConstants.storageTokenExpiry),
      ]);
    } catch (e) {
      throw const CacheException(message: 'Failed to clear session.');
    }
  }
}
