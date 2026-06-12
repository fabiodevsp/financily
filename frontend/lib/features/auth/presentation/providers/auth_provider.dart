import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/providers.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user, this.errorMessage});

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.authenticating;
}

/// Estado global de autenticação. Não usa `@riverpod` codegen — ver
/// "Decisões arquiteturais" da Fase 4 em docs/project_status.md.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._sessionExpired) : super(const AuthState()) {
    _sessionExpired.addListener(_handleSessionExpired);
    _restoreSession();
  }

  final AuthRepository _repository;
  final SessionExpiredNotifier _sessionExpired;

  @override
  void dispose() {
    _sessionExpired.removeListener(_handleSessionExpired);
    super.dispose();
  }

  void _handleSessionExpired() {
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Sessão expirada. Faça login novamente.',
    );
  }

  Future<void> _restoreSession() async {
    final user = await _repository.tryRestoreSession();
    state = user != null
        ? AuthState(status: AuthStatus.authenticated, user: user)
        : const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.authenticating);
    try {
      final user = await _repository.login(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: _messageFrom(e));
    }
  }

  Future<void> register({required String email, required String password, String? name}) async {
    state = const AuthState(status: AuthStatus.authenticating);
    try {
      final user = await _repository.register(email: email, password: password, name: name);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: _messageFrom(e));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _messageFrom(Object error) => error is ApiException ? error.message : 'Erro inesperado.';
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref.watch(sessionExpiredProvider));
});
