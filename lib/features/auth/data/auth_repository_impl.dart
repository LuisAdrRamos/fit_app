import 'package:local_auth/local_auth.dart';

import '../domain/auth_repository.dart';
import '../domain/entities/auth_result.dart';

class AuthRepositoryImpl implements AuthRepository {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AuthResult> authenticate() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Autentícate para ingresar',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return AuthResult(
        success: ok,
        message: ok ? 'Autenticación exitosa' : 'Autenticación cancelada/fallida',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Error: $e');
    }
  }
}
