import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> savePassword(String accountId, String password) async {
    await _storage.write(
      key: '${AppConstants.accountPasswordPrefix}$accountId',
      value: password,
    );
  }

  Future<String?> getPassword(String accountId) async {
    return _storage.read(
        key: '${AppConstants.accountPasswordPrefix}$accountId');
  }

  Future<void> deletePassword(String accountId) async {
    await _storage.delete(
        key: '${AppConstants.accountPasswordPrefix}$accountId');
  }

  Future<void> savePin(String pin) async {
    await _storage.write(key: AppConstants.appPinKey, value: pin);
  }

  Future<String?> getPin() async {
    return _storage.read(key: AppConstants.appPinKey);
  }

  Future<bool> hasPin() async {
    final pin = await getPin();
    return pin != null && pin.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
