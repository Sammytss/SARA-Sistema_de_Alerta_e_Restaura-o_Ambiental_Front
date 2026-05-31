import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/app_providers.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/models/usuario_local.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_mock.dart';
import '../../data/repositories/auth_repository_real.dart';
import '../access_control/user_role.dart';

/// Estado de autenticação do app.
class AuthState {
  final UsuarioLocal? usuario;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.usuario,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  bool get isAuthenticated => usuario != null;
  UserRole get currentRole => usuario?.perfil ?? UserRole.publico;

  AuthState copyWith({
    UsuarioLocal? usuario,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      usuario: clearUser ? null : (usuario ?? this.usuario),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Notifier de autenticação — gerencia login, logout e sessão persistida.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  /// Verifica sessão salva localmente (tokens + dados do usuário).
  /// Chamado no boot antes do app renderizar (ver main.dart).
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.getSavedSession();
      state = state.copyWith(
        usuario: user,
        isLoading: false,
        isInitialized: true,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, isInitialized: true);
    }
  }

  /// Autentica com email e senha.
  /// Retorna true em sucesso, false com [errorMessage] preenchido em falha.
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.login(email, password);

    if (result.isOk) {
      state = state.copyWith(
        usuario: result.valueOrNull,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorOrNull!.message,
      );
      return false;
    }
  }

  /// Encerra a sessão e limpa tokens do armazenamento seguro.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    state = const AuthState(isInitialized: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ── Providers ────────────────────────────────────────────────────

/// Escolhe a implementação de AuthRepository conforme AppConfig.useMockData.
/// Quando false (backend no ar): usa REST + JWT + SecureStore.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMockData) {
    return AuthRepositoryMock(AuthRemoteMock());
  }
  return AuthRepositoryReal(
    remote: AuthRemoteReal(ref.watch(apiClientProvider)),
    secureStore: ref.watch(secureStoreProvider),
  );
});

/// Provider global de autenticação.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

/// Provider que expõe apenas o perfil atual (para route guards, etc.).
final currentRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(authProvider).currentRole;
});

/// Provider que expõe se o usuário está autenticado.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
