class CategorySummaryModel {
  const CategorySummaryModel({required this.category, required this.total, required this.count});

  /// Valor bruto da API (ex.: `'food'`, `'transport'`, `'other'`).
  final String category;
  final double total;
  final int count;

  factory CategorySummaryModel.fromJson(Map<String, dynamic> json) => CategorySummaryModel(
    category: json['category'] as String,
    total: (json['total'] as num).toDouble(),
    count: json['count'] as int,
  );
}

class TransactionSummaryModel {
  const TransactionSummaryModel({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.transactionCount,
    required this.byCategory,
    this.dateFrom,
    this.dateTo,
  });

  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final int transactionCount;
  final List<CategorySummaryModel> byCategory;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  factory TransactionSummaryModel.fromJson(Map<String, dynamic> json) => TransactionSummaryModel(
    totalIncome: (json['total_income'] as num).toDouble(),
    totalExpenses: (json['total_expenses'] as num).toDouble(),
    balance: (json['balance'] as num).toDouble(),
    transactionCount: json['transaction_count'] as int,
    byCategory: (json['by_category'] as List)
        .map((e) => CategorySummaryModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    dateFrom: json['date_from'] == null ? null : DateTime.parse(json['date_from'] as String),
    dateTo: json['date_to'] == null ? null : DateTime.parse(json['date_to'] as String),
  );
}
