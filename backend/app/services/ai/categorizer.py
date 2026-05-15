"""
NLP transaction categorizer.
Uses TF-IDF + Logistic Regression.
Manual corrections feed back into retraining.
"""
from __future__ import annotations
import re
import joblib
from pathlib import Path
from typing import Optional

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline

from app.models.transaction import TransactionCategory

MODEL_PATH = Path(__file__).parent / "models" / "categorizer.joblib"

# Keyword heuristic rules (fast path before ML)
_RULES: dict[TransactionCategory, list[str]] = {
    TransactionCategory.FOOD:          ["ifood", "uber eats", "rappi", "mcdonalds", "restaurante", "lanche", "padaria", "mercado", "supermercado", "hortifruti"],
    TransactionCategory.TRANSPORT:     ["uber", "99", "taxi", "metro", "onibus", "posto", "gasolina", "etanol", "pedágio"],
    TransactionCategory.SUBSCRIPTIONS: ["netflix", "spotify", "amazon prime", "disney", "hbo", "youtube premium", "apple one", "icloud", "dropbox"],
    TransactionCategory.HEALTH:        ["farmácia", "drogaria", "hospital", "clínica", "médico", "plano de saúde", "unimed", "amil"],
    TransactionCategory.TRAVEL:        ["airbnb", "booking", "hotel", "pousada", "latam", "gol", "azul", "tam"],
    TransactionCategory.ENTERTAINMENT: ["cinema", "show", "teatro", "ingresso", "steam", "playstation", "xbox"],
    TransactionCategory.BILLS:         ["energia", "água", "internet", "telefone", "claro", "vivo", "tim", "aluguel", "condomínio"],
    TransactionCategory.SALARY:        ["salário", "pagamento", "folha", "pro-labore", "remuneração"],
    TransactionCategory.INVESTMENTS:   ["tesouro", "cdb", "ação", "fii", "ativo", "aplicação", "resgate"],
    TransactionCategory.SHOPPING:      ["amazon", "mercado livre", "shopee", "americanas", "casas bahia", "renner", "zara"],
}


class TransactionCategorizer:
    def __init__(self) -> None:
        self._model: Optional[Pipeline] = None
        self._load_model()

    def categorize(self, description: str) -> tuple[TransactionCategory, float]:
        """Returns (category, confidence_score 0-1)."""
        normalized = self._normalize(description)

        # Fast path: keyword rules
        rule_cat = self._apply_rules(normalized)
        if rule_cat:
            return rule_cat, 0.95

        # ML path
        if self._model:
            proba = self._model.predict_proba([normalized])[0]
            idx   = np.argmax(proba)
            label = self._model.classes_[idx]
            return TransactionCategory(label), float(proba[idx])

        return TransactionCategory.OTHER, 0.0

    def train(self, descriptions: list[str], labels: list[str]) -> None:
        pipeline = Pipeline([
            ("tfidf", TfidfVectorizer(ngram_range=(1, 2), min_df=2, max_features=10_000)),
            ("clf",   LogisticRegression(max_iter=1000, C=5.0)),
        ])
        pipeline.fit(descriptions, labels)
        MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
        joblib.dump(pipeline, MODEL_PATH)
        self._model = pipeline

    def _load_model(self) -> None:
        if MODEL_PATH.exists():
            self._model = joblib.load(MODEL_PATH)

    @staticmethod
    def _normalize(text: str) -> str:
        return re.sub(r"[^a-záéíóúàâêôãõü\s]", " ", text.lower()).strip()

    @staticmethod
    def _apply_rules(text: str) -> Optional[TransactionCategory]:
        for category, keywords in _RULES.items():
            if any(k in text for k in keywords):
                return category
        return None


# Singleton instance
categorizer = TransactionCategorizer()
