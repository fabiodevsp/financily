import 'dart:convert';

/// Decodifica o payload de um JWT sem validar assinatura.
///
/// Usado apenas para extrair o claim `sub` (user id) do access token
/// retornado por `/auth/login`, já que o backend não expõe um endpoint
/// `/users/me`. A validade do token é responsabilidade do backend.
Map<String, dynamic> decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw const FormatException('Token JWT inválido');
  }
  final normalized = base64Url.normalize(parts[1]);
  final payload = utf8.decode(base64Url.decode(normalized));
  return jsonDecode(payload) as Map<String, dynamic>;
}
