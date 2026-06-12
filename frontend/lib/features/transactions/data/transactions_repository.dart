import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'models/transaction_model.dart';
import 'models/transaction_summary_model.dart';

/// Acesso a `/api/v1/transactions/*`. Sem camada `domain/` separada nesta
/// fase (ver "Decisões arquiteturais" da Fase 4) — repositório concreto
/// consumido diretamente pelos providers Riverpod.
class TransactionsRepository {
  TransactionsRepository(this._dio);

  final Dio _dio;

  Future<TransactionListModel> getTransactions({
    int skip = 0,
    int limit = 50,
    String? category,
    String? type,
    String? search,
    String sortBy = 'date',
    String order = 'desc',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/transactions/',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (category != null) 'category': category,
          if (type != null) 'type': type,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'sort_by': sortBy,
          'order': order,
        },
      );
      return TransactionListModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<TransactionSummaryModel> getSummary({DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/transactions/summary',
        queryParameters: {
          if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
          if (dateTo != null) 'date_to': dateTo.toIso8601String(),
        },
      );
      return TransactionSummaryModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
