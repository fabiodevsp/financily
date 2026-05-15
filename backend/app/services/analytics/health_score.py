"""
Financial Health Score engine (0–100).

Dimensions:
  control  — categorization completeness + budget adherence
  savings  — income/expense ratio
  forecast — projected balance 90d
  debt     — installment burden
"""
from dataclasses import dataclass
from typing import Sequence
import pandas as pd


@dataclass
class HealthScore:
    total:          float  # weighted average
    control:        float
    savings:        float
    forecast:       float
    debt:           float
    label:          str    # CRÍTICO | RUIM | REGULAR | BOM | ÓTIMO
    insight:        str


def compute_health_score(
    transactions: Sequence[dict],
    monthly_income: float,
) -> HealthScore:
    df = pd.DataFrame(transactions)

    control  = _control_score(df)
    savings  = _savings_score(df, monthly_income)
    forecast = _forecast_score(df, monthly_income)
    debt     = _debt_score(df, monthly_income)

    total = (control * 0.30 + savings * 0.30 + forecast * 0.25 + debt * 0.15)
    total = round(min(max(total, 0), 100), 1)

    label, insight = _label(total, savings, debt)
    return HealthScore(total=total, control=control, savings=savings,
                       forecast=forecast, debt=debt, label=label, insight=insight)


def _control_score(df: pd.DataFrame) -> float:
    if df.empty:
        return 50.0
    categorized = df[df["category"] != "other"].shape[0]
    ratio       = categorized / len(df) if len(df) > 0 else 0
    return round(ratio * 100, 1)


def _savings_score(df: pd.DataFrame, income: float) -> float:
    if income <= 0:
        return 0.0
    expenses = df[df["type"] == "debit"]["amount"].sum()
    rate     = 1 - (expenses / income)
    return round(max(min(rate * 100, 100), 0), 1)


def _forecast_score(df: pd.DataFrame, income: float) -> float:
    if df.empty or income <= 0:
        return 50.0
    monthly_exp = df[df["type"] == "debit"]["amount"].sum()
    burn_ratio  = monthly_exp / income
    if burn_ratio < 0.5:   return 95.0
    if burn_ratio < 0.7:   return 80.0
    if burn_ratio < 0.85:  return 65.0
    if burn_ratio < 1.0:   return 45.0
    return 20.0


def _debt_score(df: pd.DataFrame, income: float) -> float:
    installments = df[df["is_installment"] == True]["amount"].sum()
    if income <= 0:
        return 50.0
    burden = installments / income
    if burden < 0.1:  return 100.0
    if burden < 0.2:  return 80.0
    if burden < 0.3:  return 60.0
    if burden < 0.4:  return 40.0
    return 20.0


def _label(score: float, savings: float, debt: float) -> tuple[str, str]:
    if score >= 85:
        return "ÓTIMO", "Parabéns! Sua saúde financeira está excelente. Continue assim."
    if score >= 70:
        return "BOM", f"Bom controle. Foco em economizar mais — savings score: {savings:.0f}/100."
    if score >= 55:
        return "REGULAR", "Há espaço para melhorar. Revise assinaturas e gastos recorrentes."
    if score >= 40:
        return "RUIM", "Atenção: despesas comprometendo renda. Reduza gastos não essenciais."
    return "CRÍTICO", "Situação crítica. Suas despesas superam sua renda. Aja agora."
