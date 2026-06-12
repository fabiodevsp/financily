import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transaction_summary_model.dart';
import '../providers/transactions_provider.dart';
import '../widgets/category_ui.dart';

final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

String _errorMessage(Object error) => error is ApiException ? error.message : 'Não foi possível carregar o resumo.';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(transactionsSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Resumo Financeiro', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.cyan,
        backgroundColor: AppColors.card,
        onRefresh: () => ref.refresh(transactionsSummaryProvider.future),
        child: summaryAsync.when(
          data: (summary) => _buildContent(summary),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
          error: (error, _) => _buildErrorState(
            message: _errorMessage(error),
            onRetry: () => ref.invalidate(transactionsSummaryProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(TransactionSummaryModel summary) {
    final byCategory = [...summary.byCategory]..sort((a, b) => b.total.abs().compareTo(a.total.abs()));
    final maxTotal = byCategory.isEmpty ? 1.0 : byCategory.map((c) => c.total.abs()).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _BalanceCard(balance: summary.balance, transactionCount: summary.transactionCount),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Receitas',
                value: summary.totalIncome,
                color: AppColors.income,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Despesas',
                value: summary.totalExpenses,
                color: AppColors.expense,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Por categoria', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 12),
        if (byCategory.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Nenhuma transação categorizada ainda.', style: TextStyle(color: AppColors.muted, fontSize: 14)),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    for (final category in byCategory) ...[
                      _CategoryRow(category: category, ratio: category.total.abs() / maxTotal),
                      if (category != byCategory.last) const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

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

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.transactionCount});

  final double balance;
  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.cyan.withOpacity(0.12), AppColors.purple.withOpacity(0.12)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Saldo do período', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                _currencyFormat.format(balance),
                style: TextStyle(
                  color: isPositive ? AppColors.income : AppColors.expense,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text('$transactionCount transações no período', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.color, required this.icon});

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _currencyFormat.format(value),
                style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.ratio});

  final CategorySummaryModel category;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final ui = categoryUiFor(category.category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(ui.icon, color: ui.color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(ui.label, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Text(
              _currencyFormat.format(category.total),
              style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(ui.color),
          ),
        ),
      ],
    );
  }
}
