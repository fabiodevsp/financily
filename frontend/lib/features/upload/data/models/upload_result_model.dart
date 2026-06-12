class UploadResultModel {
  const UploadResultModel({
    required this.id,
    required this.fileName,
    this.bankDetected,
    required this.status,
    this.errorMessage,
    this.processedAt,
    required this.createdAt,
    required this.transactionsCreated,
    required this.duplicatesSkipped,
  });

  final String id;
  final String fileName;
  final String? bankDetected;
  /// Valor bruto da API: `'pending' | 'processing' | 'completed' | 'failed'`.
  final String status;
  final String? errorMessage;
  final DateTime? processedAt;
  final DateTime createdAt;
  final int transactionsCreated;
  final int duplicatesSkipped;

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  factory UploadResultModel.fromJson(Map<String, dynamic> json) => UploadResultModel(
    id: json['id'] as String,
    fileName: json['file_name'] as String,
    bankDetected: json['bank_detected'] as String?,
    status: json['status'] as String,
    errorMessage: json['error_message'] as String?,
    processedAt: json['processed_at'] == null ? null : DateTime.parse(json['processed_at'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    transactionsCreated: json['transactions_created'] as int,
    duplicatesSkipped: json['duplicates_skipped'] as int,
  );
}
