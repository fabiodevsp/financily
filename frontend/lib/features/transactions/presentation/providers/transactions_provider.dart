import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_summary_model.dart';
import '../../data/transactions_repository.dart';

/// Filtros aplicados à listagem de transações. Valores `null` significam
/// "sem filtro" (a API ignora o parâmetro quando ausente).
class TransactionsFilter {
  const TransactionsFilter({this.category, this.type, this.search});

  final String? category;
  final String? type;
  final String? search;
}

/// Estado dos filtros da tela de transações. Não usa `@riverpod` codegen —
/// ver "Decisões arquiteturais" da Fase 4 em docs/project_status.md.
class TransactionsFilterNotifier extends StateNotifier<TransactionsFilter> {
  TransactionsFilterNotifier() : super(const TransactionsFilter());

  void setCategory(String? category) => state = TransactionsFilter(category: category, type: state.type, search: state.search);

  void setType(String? type) => state = TransactionsFilter(category: state.category, type: type, search: state.search);

  void setSearch(String? search) => state = TransactionsFilter(category: state.category, type: state.type, search: search);

  void clear() => state = const TransactionsFilter();
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(ref.watch(dioProvider));
});

final transactionsFilterProvider = StateNotifierProvider<TransactionsFilterNotifier, TransactionsFilter>((ref) {
  return TransactionsFilterNotifier();
});

/// Lista de transações para os filtros atuais. `autoDispose` para sempre
/// refletir o estado mais recente quando a tela é reaberta; use
/// `ref.refresh(transactionsProvider)` para forçar atualização (pull-to-refresh).
final transactionsProvider = FutureProvider.autoDispose<TransactionListModel>((ref) {
  final filter = ref.watch(transactionsFilterProvider);
  final repository = ref.watch(transactionsRepositoryProvider);
  return repository.getTransactions(
    category: filter.category,
    type: filter.type,
    search: filter.search,
  );
});

final transactionsSummaryProvider = FutureProvider.autoDispose<TransactionSummaryModel>((ref) {
  return ref.watch(transactionsRepositoryProvider).getSummary();
});
