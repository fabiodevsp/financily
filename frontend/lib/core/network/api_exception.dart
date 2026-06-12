import 'package:dio/dio.dart';

/// Erro de API normalizado com mensagem amigável em PT-BR.
///
/// Toda chamada de repositório deve capturar [DioException] e relançar
/// como [ApiException], para que a UI nunca precise conhecer detalhes
/// do Dio.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'Tempo de conexão esgotado. Verifique se o servidor está em execução.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Não foi possível conectar ao servidor. Verifique sua conexão.',
        );
      default:
        break;
    }

    final statusCode = error.response?.statusCode;
    final detail = _extractDetail(error.response?.data);

    switch (statusCode) {
      case 400:
        return ApiException(detail ?? 'Requisição inválida.', statusCode: statusCode);
      case 401:
        return ApiException(detail ?? 'Sessão expirada. Faça login novamente.', statusCode: statusCode);
      case 404:
        return ApiException(detail ?? 'Recurso não encontrado.', statusCode: statusCode);
      case 409:
        return ApiException(detail ?? 'Conflito de dados.', statusCode: statusCode);
      case 413:
        return ApiException(detail ?? 'Arquivo muito grande.', statusCode: statusCode);
      case 422:
        return ApiException(detail ?? 'Dados inválidos.', statusCode: statusCode);
    }

    return ApiException(
      detail ?? 'Erro inesperado ao comunicar com o servidor.',
      statusCode: statusCode,
    );
  }

  static String? _extractDetail(dynamic data) {
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) return detail;
      return detail.toString();
    }
    return null;
  }

  @override
  String toString() => message;
}
