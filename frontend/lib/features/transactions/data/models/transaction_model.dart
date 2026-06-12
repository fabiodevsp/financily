class TransactionModel {
  const TransactionModel({
    required this.id,
    this.uploadId,
    required this.date,
    required this.description,
    this.merchant,
    required this.amount,
    required this.type,
    required this.category,
    this.subcategory,
    required this.isRecurring,
    required this.isSubscription,
    required this.isInstallment,
    this.installmentCurrent,
    this.installmentTotal,
    required this.confidenceScore,
    required this.createdAt,
  });

  final String id;
  final String? uploadId;
  final DateTime date;
  final String description;
  final String? merchant;
  final double amount;
  /// Valor bruto da API: `'debit'` ou `'credit'`.
  final String type;
  /// Valor bruto da API (ex.: `'food'`, `'transport'`, `'other'`).
  final String category;
  final String? subcategory;
  final bool isRecurring;
  final bool isSubscription;
  final bool isInstallment;
  final double? installmentCurrent;
  final double? installmentTotal;
  final double confidenceScore;
  final DateTime createdAt;

  bool get isCredit => type == 'credit';

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    id: json['id'] as String,
    uploadId: json['upload_id'] as String?,
    date: DateTime.parse(json['date'] as String),
    description: json['description'] as String,
    merchant: json['merchant'] as String?,
    amount: (json['amount'] as num).toDouble(),
    type: json['type'] as String,
    category: json['category'] as String,
    subcategory: json['subcategory'] as String?,
    isRecurring: json['is_recurring'] as bool,
    isSubscription: json['is_subscription'] as bool,
    isInstallment: json['is_installment'] as bool,
    installmentCurrent: (json['installment_current'] as num?)?.toDouble(),
    installmentTotal: (json['installment_total'] as num?)?.toDouble(),
    confidenceScore: (json['confidence_score'] as num).toDouble(),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class TransactionListModel {
  const TransactionListModel({
    required this.items,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<TransactionModel> items;
  final int total;
  final int skip;
  final int limit;

  bool get hasMore => skip + items.length < total;

  factory TransactionListModel.fromJson(Map<String, dynamic> json) => TransactionListModel(
    items: (json['items'] as List)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: json['total'] as int,
    skip: json['skip'] as int,
    limit: json['limit'] as int,
  );
}
