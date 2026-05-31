import '../../core/network/api_exception.dart';
import '../../core/network/result.dart';
import '../../core/security/secure_store.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/usuario_local.dart';
import 'auth_repository.dart';

/// Implementação real de AuthRepository.
/// Persiste accessToken, refreshToken e dados do usuário no Keystore/Keychain.
class AuthRepositoryReal implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final SecureStore _secureStore;

  AuthRepositoryReal({
    required AuthRemoteDatasource remote,
    required SecureStore secureStore,
  })  : _remote = remote,
        _secureStore = secureStore;

  @override
  Future<Result<UsuarioLocal>> login(String email, String password) async {
    final result = await _remote.login(email, password);
    if (result.isErr) return Err(result.errorOrNull!);

    final response = result.valueOrNull!;
    await _secureStore.setAccessToken(response.accessToken);
    await _secureStore.setRefreshToken(response.refreshToken);

    final user = UsuarioLocal.fromMap(response.usuario).copyWith(
      token: response.accessToken,
      ultimoLogin: DateTime.now(),
    );
    await _secureStore.setUserJson(user.toMap());
    return Ok(user);
  }

  @override
  Future<Result<String>> refreshToken() async {
    final token = await _secureStore.getRefreshToken();
    if (token == null) {
      return Err(const ApiException(
        message: 'Sessão expirada. Faça login novamente.',
        type: ApiErrorType.unauthorized,
      ));
    }
    final result = await _remote.refreshAccessToken(token);
    if (result.isOk) {
      await _secureStore.setAccessToken(result.valueOrNull!);
    }
    return result;
  }

  @override
  Future<void> logout() async {
    await _secureStore.clearAll();
  }

  @override
  Future<UsuarioLocal?> getSavedSession() async {
    final token = await _secureStore.getAccessToken();
    final userJson = await _secureStore.getUserJson();
    if (token == null || userJson == null) return null;
    return UsuarioLocal.fromMap(userJson).copyWith(token: token);
  }
}
