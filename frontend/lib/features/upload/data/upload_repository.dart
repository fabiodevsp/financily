import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/api_exception.dart';
import 'models/upload_result_model.dart';

/// Acesso a `/api/v1/uploads/*`. Sem camada `domain/` separada nesta fase
/// (ver "Decisões arquiteturais" da Fase 4) — repositório concreto
/// consumido diretamente pelos providers Riverpod.
class UploadRepository {
  UploadRepository(this._dio);

  final Dio _dio;

  Future<UploadResultModel> uploadPdf({
    required String filePath,
    required String fileName,
    required String bank,
  }) async {
    try {
      final formData = FormData.fromMap({
        'bank': bank,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>('/api/v1/uploads/pdf', data: formData);
      return UploadResultModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
