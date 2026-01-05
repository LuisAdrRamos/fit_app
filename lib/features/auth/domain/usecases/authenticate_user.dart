import '../auth_repository.dart';
import '../entities/auth_result.dart';

class AuthenticateUser {
  final AuthRepository _repo;

  AuthenticateUser(this._repo);

  Future<AuthResult> call() async {
    final canAuth = await _repo.canAuthenticate();
    if (!canAuth) {
      return const AuthResult(
        success: false,
        message: 'Biometría no disponible en este dispositivo',
      );
    }
    return _repo.authenticate();
  }
}
