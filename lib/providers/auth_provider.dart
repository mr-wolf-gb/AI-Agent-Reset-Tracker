import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_service.dart';
import 'service_providers.dart';

enum AuthStatus { unauthenticated, authenticated }

class AuthNotifier extends StateNotifier<AuthStatus> {
  AuthNotifier(this._bio) : super(AuthStatus.unauthenticated);

  final BiometricService _bio;

  Future<bool> authenticate() async {
    final ok = await _bio.authenticate();
    if (ok) state = AuthStatus.authenticated;
    return ok;
  }

  void markAuthenticated() => state = AuthStatus.authenticated;
  void logout() => state = AuthStatus.unauthenticated;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  final bio = ref.watch(biometricServiceProvider);
  return AuthNotifier(bio);
});
