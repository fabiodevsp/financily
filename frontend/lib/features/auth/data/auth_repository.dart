import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/utils/jwt_utils.dart';
import 'models/token_pair.dart';
import 'models/user_model.dart';

/// Acesso a `/api/v1/auth/*`. Sem camada `domain/` separada nesta fase
/// (ver "Decisões arquiteturais" da Fase 4) — repositório concreto
/// consumido diretamente pelos providers Riverpod.
class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Registra um novo usuário e, em caso de sucesso, autentica
  /// imediatamente com as mesmas credenciais (o backend não retorna
  /// tokens em `/auth/register`).
  Future<UserModel> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/register',
        data: {
          'email': email,
          'password': password,
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        },
      );
      final registeredUser = UserModel.fromJson(response.data!);
      return login(email, password, cachedUser: registeredUser);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Autentica via `/auth/login` (OAuth2 password flow) e persiste os
  /// tokens. Como o backend não expõe `/users/me`, o usuário autenticado
  /// é reconstruído a partir do claim `sub` (id) do access token; o
  /// e-mail vem do formulário e o `name` é preenchido só quando
  /// disponível (ex.: vindo de [register]).
  Future<UserModel> login(String email, String password, {UserModel? cachedUser}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: {'username': email, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final tokens = TokenPair.fromJson(response.data!);
      await _tokenStorage.saveTokens(tokens);

      final user = cachedUser ?? _userFromAccessToken(tokens.accessToken, email: email);
      await _tokenStorage.saveUser(user);
      return user;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Restaura a sessão salva, se houver tokens e usuário em cache.
  /// Não valida o access token contra o backend — se estiver expirado,
  /// o [AuthInterceptor] tentará renovar na primeira chamada autenticada.
  Future<UserModel?> tryRestoreSession() async {
    final accessToken = await _tokenStorage.getAccessToken();
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (accessToken == null || refreshToken == null) return null;
    return _tokenStorage.getUser();
  }

  Future<void> logout() => _tokenStorage.clear();

  UserModel _userFromAccessToken(String accessToken, {required String email}) {
    try {
      final payload = decodeJwtPayload(accessToken);
      return UserModel(id: payload['sub'] as String, email: email);
    } catch (_) {
      return UserModel(id: '', email: email);
    }
  }
}
