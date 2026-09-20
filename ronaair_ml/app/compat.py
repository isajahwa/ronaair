"""
compat.py - kompatibilitas pemuatan model hasil training RonaAir.

MASALAH
-------
`ronaair_do_xgboost_final.joblib` adalah sklearn Pipeline yang berisi kelas buatan
sendiri `AquacultureFeatureEngineer`. Kelas itu didefinisikan di dalam notebook Colab
(modul `__main__`), sehingga pickle hanya menyimpan REFERENSI "__main__.AquacultureFeatureEngineer",
bukan kodenya. Di luar notebook, `joblib.load(...)` gagal dengan
`AttributeError: Can't get attribute 'AquacultureFeatureEngineer' on <module '__main__'>`.

SOLUSI
------
Modul ini menyalin definisi kelas PERSIS seperti di notebook
(RonaAir_DO_XGBoost_Final.ipynb, "CELL 10-12") lalu mendaftarkannya ke `__main__`
sebelum joblib.load dipanggil.

PENTING: definisi di bawah HARUS identik dengan notebook. Jangan ubah rumus fitur
tanpa melatih ulang model. Jika Anda melatih ulang, simpan kelas ini di modul
sendiri (bukan di notebook) supaya masalah ini hilang.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.base import BaseEstimator, TransformerMixin

# --- Konstanta yang dipakai kelas di bawah (identik dengan notebook DO) -----------------
BASE_COLS = ["temp_c", "ph", "turbidity_ntu"]
CYCLICAL_COLS = ["hour_sin", "hour_cos", "month_sin", "month_cos"]
RAW_INPUT_COLS = BASE_COLS + CYCLICAL_COLS  # urutan kolom input model (7 kolom)
TARGET_COL = "do_mgl"

# Batas fisik yang dipakai saat cleaning data training (untuk validasi input di service).
PHYS_BOUNDS = {
    "temp_c": (10.0, 40.0),
    "ph": (4.0, 10.5),
    "do_mgl": (0.0001, 30.0),
}


class AquacultureFeatureEngineer(BaseEstimator, TransformerMixin):
    """Blok feature-engineering di dalam Pipeline (salinan persis dari notebook)."""

    def fit(self, X, y=None):
        X = pd.DataFrame(X, columns=RAW_INPUT_COLS)
        self.medians_ = X[BASE_COLS].median()
        return self

    def transform(self, X):
        X = pd.DataFrame(X, columns=RAW_INPUT_COLS).copy()
        X[BASE_COLS] = X[BASE_COLS].fillna(self.medians_)
        t, ph, turb = X["temp_c"], X["ph"], X["turbidity_ntu"]

        out = pd.DataFrame(index=X.index)
        out["temp_c"] = t
        out["ph"] = ph
        out["turbidity_ntu"] = turb
        # Polinomial saturasi DO (Benson & Krause / APHA, air tawar, permukaan laut)
        out["do_saturation_theory"] = 14.652 - 0.41022 * t + 0.007991 * t**2 - 0.000077774 * t**3
        out["temp_sq"] = t ** 2
        out["ph_temp_interaction"] = ph * t
        out["turbidity_log1p"] = np.log1p(turb)
        out["algae_proxy_index"] = out["turbidity_log1p"] * ph
        for c in CYCLICAL_COLS:
            out[c] = X[c]
        return out

    def get_feature_names_out(self, input_features=None):
        return np.array(
            ["temp_c", "ph", "turbidity_ntu", "do_saturation_theory", "temp_sq",
             "ph_temp_interaction", "turbidity_log1p", "algae_proxy_index"] + CYCLICAL_COLS
        )


def register_for_unpickle() -> None:
    """Daftarkan kelas ke modul `__main__` agar joblib/pickle dapat menemukannya."""
    main = sys.modules["__main__"]
    setattr(main, "AquacultureFeatureEngineer", AquacultureFeatureEngineer)


def build_do_input_row(temp_c, ph, turbidity_ntu, timestamp) -> pd.DataFrame:
    """Bentuk satu baris input DO sesuai feature_schema.json.

    - turbidity_ntu boleh None/NaN (diimputasi median training oleh pipeline).
    - timestamp: datetime / string ISO; dipakai untuk fitur siklus jam & bulan.
    """
    ts = pd.to_datetime(timestamp)
    hour = ts.hour + ts.minute / 60.0
    return pd.DataFrame([{
        "temp_c": temp_c,
        "ph": ph,
        "turbidity_ntu": np.nan if turbidity_ntu is None else turbidity_ntu,
        "hour_sin": np.sin(2 * np.pi * hour / 24),
        "hour_cos": np.cos(2 * np.pi * hour / 24),
        "month_sin": np.sin(2 * np.pi * ts.month / 12),
        "month_cos": np.cos(2 * np.pi * ts.month / 12),
    }], columns=RAW_INPUT_COLS)


def load_do_pipeline(path: str | Path):
    """Muat pipeline DO (joblib) dengan aman di luar notebook."""
    import joblib

    register_for_unpickle()
    return joblib.load(path)
