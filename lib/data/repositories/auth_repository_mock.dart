import '../../core/network/result.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/usuario_local.dart';
import 'auth_repository.dart';

/// Implementação mock de AuthRepository.
/// Sessão em memória — não persiste entre reinicializações do app.
class AuthRepositoryMock implements AuthRepository {
  final AuthRemoteDatasource _remote;
  UsuarioLocal? _cached;

  AuthRepositoryMock(this._remote);

  @override
  Future<Result<UsuarioLocal>> login(String email, String password) async {
    final result = await _remote.login(email, password);
    if (result.isErr) return Err(result.errorOrNull!);

    final response = result.valueOrNull!;
    final user = UsuarioLocal.fromMap(response.usuario).copyWith(
      token: response.accessToken,
      ultimoLogin: DateTime.now(),
    );
    _cached = user;
    return Ok(user);
  }

  @override
  Future<Result<String>> refreshToken() =>
      _remote.refreshAccessToken('mock_refresh');

  @override
  Future<void> logout() async {
    _cached = null;
  }

  @override
  Future<UsuarioLocal?> getSavedSession() async => _cached;
}
