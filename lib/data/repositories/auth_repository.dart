import '../../core/network/result.dart';
import '../models/usuario_local.dart';

/// Contrato de autenticação.
/// Implementações: AuthRepositoryMock (dados locais) e AuthRepositoryReal (REST + JWT).
abstract class AuthRepository {
  /// Autentica com email e senha. Persiste tokens se bem-sucedido.
  Future<Result<UsuarioLocal>> login(String email, String password);

  /// Renova o accessToken usando o refreshToken armazenado.
  Future<Result<String>> refreshToken();

  /// Remove sessão (tokens + dados do usuário) do armazenamento local.
  Future<void> logout();

  /// Retorna o usuário salvo localmente (null se não há sessão ativa).
  Future<UsuarioLocal?> getSavedSession();
}
