import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Aparência (label PT-BR, ícone, cor) para cada valor de
/// `TransactionCategory` retornado pela API (sempre em minúsculas).
class CategoryUi {
  const CategoryUi(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

const Map<String, CategoryUi> _categoryUiMap = {
  'food': CategoryUi('Alimentação', Icons.restaurant_rounded, AppColors.amber),
  'transport': CategoryUi('Transporte', Icons.directions_car_filled_rounded, AppColors.cyan),
  'shopping': CategoryUi('Compras', Icons.shopping_bag_rounded, AppColors.purple),
  'subscriptions': CategoryUi('Assinaturas', Icons.subscriptions_rounded, AppColors.purple),
  'health': CategoryUi('Saúde', Icons.local_hospital_rounded, AppColors.expense),
  'travel': CategoryUi('Viagem', Icons.flight_takeoff_rounded, AppColors.cyan),
  'entertainment': CategoryUi('Entretenimento', Icons.movie_rounded, AppColors.purple),
  'bills': CategoryUi('Contas', Icons.receipt_long_rounded, AppColors.amber),
  'salary': CategoryUi('Salário', Icons.attach_money_rounded, AppColors.income),
  'investments': CategoryUi('Investimentos', Icons.trending_up_rounded, AppColors.income),
  'other': CategoryUi('Outros', Icons.category_rounded, AppColors.muted),
};

const CategoryUi _fallbackCategoryUi = CategoryUi('Outros', Icons.category_rounded, AppColors.muted);

CategoryUi categoryUiFor(String category) => _categoryUiMap[category] ?? _fallbackCategoryUi;
