import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transactions_provider.dart';
import '../widgets/category_ui.dart';

final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

const Map<String, String> _categoryOptions = {
  'food': 'Alimentação',
  'transport': 'Transporte',
  'shopping': 'Compras',
  'subscriptions': 'Assinaturas',
  'health': 'Saúde',
  'travel': 'Viagem',
  'entertainment': 'Entretenimento',
  'bills': 'Contas',
  'salary': 'Salário',
  'investments': 'Investimentos',
  'other': 'Outros',
};

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String _errorMessage(Object error) => error is ApiException ? error.message : 'Não foi possível carregar as transações.';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Transações', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          const _FiltersBar(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.cyan,
              backgroundColor: AppColors.card,
              onRefresh: () => ref.refresh(transactionsProvider.future),
              child: transactionsAsync.when(
                data: (list) => list.items.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        itemCount: list.items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index == list.items.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Center(
                                child: Text(
                                  'Mostrando ${list.items.length} de ${list.total}',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                ),
                              ),
                            );
                          }
                          return _TransactionTile(transaction: list.items[index]);
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
                error: (error, _) => _buildErrorState(
                  message: _errorMessage(error),
                  onRetry: () => ref.invalidate(transactionsProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.receipt_long_rounded, color: AppColors.muted, size: 56),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Nenhuma transação encontrada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 15),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Envie um extrato em PDF para começar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
        ],
      );

  Widget _buildErrorState({required String message, required VoidCallback onRetry}) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 56),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cyan,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tentar novamente'),
            ),
          ),
        ],
      );
}

class _FiltersBar extends ConsumerStatefulWidget {
  const _FiltersBar();

  @override
  ConsumerState<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends ConsumerState<_FiltersBar> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(transactionsFilterProvider);
    final notifier = ref.read(transactionsFilterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.white),
            onSubmitted: (value) => notifier.setSearch(value.trim().isEmpty ? null : value.trim()),
            decoration: InputDecoration(
              hintText: 'Buscar por descrição...',
              hintStyle: const TextStyle(color: AppColors.muted),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
              suffixIcon: filter.search == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                      onPressed: () {
                        _searchCtrl.clear();
                        notifier.setSearch(null);
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Pill(label: 'Todas', selected: filter.type == null, onTap: () => notifier.setType(null)),
                const SizedBox(width: 8),
                _Pill(label: 'Receitas', selected: filter.type == 'credit', onTap: () => notifier.setType('credit')),
                const SizedBox(width: 8),
                _Pill(label: 'Despesas', selected: filter.type == 'debit', onTap: () => notifier.setType('debit')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Pill(label: 'Todas categorias', selected: filter.category == null, onTap: () => notifier.setCategory(null)),
                for (final entry in _categoryOptions.entries) ...[
                  const SizedBox(width: 8),
                  _Pill(label: entry.value, selected: filter.category == entry.key, onTap: () => notifier.setCategory(entry.key)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.cyan.withOpacity(0.15) : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.cyan : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.cyan : AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final categoryUi = categoryUiFor(transaction.category);
    final isCredit = transaction.isCredit;
    final amountColor = isCredit ? AppColors.income : AppColors.expense;
    final amountText = '${isCredit ? '+' : '-'} ${_currencyFormat.format(transaction.amount.abs())}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryUi.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(categoryUi.icon, color: categoryUi.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${categoryUi.label} · ${_formatDate(transaction.date)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amountText,
                style: TextStyle(color: amountColor, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
