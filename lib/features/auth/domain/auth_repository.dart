import 'entities/auth_result.dart';

abstract class AuthRepository {
  Future<bool> canAuthenticate();
  Future<AuthResult> authenticate();
}
