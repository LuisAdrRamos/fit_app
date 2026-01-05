import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/usecases/authenticate_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthenticateUser authenticateUser;

  AuthBloc(this.authenticateUser) : super(const AuthState.initial()) {
    on<AuthRequested>(_onAuthRequested);
    on<AuthReset>(_onAuthReset);
  }

  Future<void> _onAuthRequested(AuthRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    final result = await authenticateUser();
    if (result.success) {
      emit(state.copyWith(status: AuthStatus.success, message: result.message));
    } else {
      emit(state.copyWith(status: AuthStatus.failure, message: result.message ?? 'Falló'));
    }
  }

  void _onAuthReset(AuthReset event, Emitter<AuthState> emit) {
    emit(const AuthState.initial());
  }
}
