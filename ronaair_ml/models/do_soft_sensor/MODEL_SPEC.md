# MODEL_SPEC - `do_soft_sensor` (Estimated Dissolved Oxygen)

| | |
|---|---|
| Sumber | `RonaAir_DO_XGBoost_Final.ipynb` |
| Nama model | `RonaAir_DO_SoftSensor_XGBoost` |
| Jenis | Regresi tabular (sklearn Pipeline: `AquacultureFeatureEngineer` → `StandardScaler` → `XGBRegressor`) |
| Versi aktif | `v1` (folder `models/do_soft_sensor/v1/`) |
| Endpoint rencana | `POST /predict/do` |
| Peran | Menghasilkan `do_est` untuk `risk_fusion` |
| Status | Aktif, **validitas terbatas** (lihat "Batasan") |

## 1. Artefak (di `v1/`)

| File | Status |
|---|---|
| `ronaair_do_xgboost_final.joblib` | WAJIB |
| `feature_schema.json` | WAJIB |
| `model_metadata.json`, `model_card.md` | PENDUKUNG |

Daftar lengkap dan asal file: `../../ARTIFACTS.md`.

## 2. Cara memuat (WAJIB)

```python
from app.compat import load_do_pipeline, build_do_input_row
model = load_do_pipeline("models/do_soft_sensor/v1/ronaair_do_xgboost_final.joblib")
```

`joblib.load` langsung akan gagal (`AttributeError: ... 'AquacultureFeatureEngineer' on <module '__main__'>`) karena kelas kustom dulunya didefinisikan di notebook. `app/compat.py` memuat salinan persis kelas itu.
Butuh `xgboost` terpasang dengan versi yang sama dengan training (lihat `env_versions.json`).

## 3. Kontrak input

Urutan kolom yang dilihat pipeline (7 kolom, `RAW_INPUT_COLS`):

`temp_c, ph, turbidity_ntu, hour_sin, hour_cos, month_sin, month_cos`

Dari API cukup terima:

| Field | Tipe | Satuan | Rentang valid | Catatan |
|---|---|---|---|---|
| `temp_c` | float | °C | 10.0 - 40.0 | Rentang data latih setelah cleaning: 14.5 - 40.0. Di luar 10-40 → tolak/peringatan. |
| `ph` | float | pH | 4.0 - 10.5 | Gunakan `ph_sensor` (probe ESP32). |
| `turbidity_ntu` | float atau null | NTU | ≥ 0 | **Boleh null.** Diimputasi median training oleh pipeline. ESP32 RonaAir umumnya tidak punya sensor ini. |
| `timestamp` | datetime | - | - | Diturunkan menjadi 4 fitur siklus di bawah. Tentukan zona waktu (lihat INTEGRATION_NOTES D5). |

Fitur siklus (dihitung `build_do_input_row`):

```
hour  = jam + menit/60
hour_sin  = sin(2π·hour/24)      hour_cos  = cos(2π·hour/24)
month_sin = sin(2π·bulan/12)     month_cos = cos(2π·bulan/12)
```

Fitur turunan di dalam pipeline (jangan dihitung ulang di luar): `do_saturation_theory` (polinomial Benson-Krause), `temp_sq`, `ph_temp_interaction`, `turbidity_log1p`, `algae_proxy_index`.

## 4. Kontrak output

```json
{
  "do_est": 0.0,
  "unit": "mg/L",
  "ui_label": "Estimated DO",
  "model": "RonaAir_DO_SoftSensor_XGBoost",
  "model_version": "v1",
  "warnings": []
}
```

- `do_est` = hasil `model.predict(row)[0]` (float). Rentang plausibel 0 - 25 mg/L; di luar itu → peringatan, jangan dibuang diam-diam.
- Jangan pernah melabelinya "Measured DO".
- Tambahkan peringatan bila input di luar rentang latih (mis. `temp_c` < 14.5 atau turbidity sangat tinggi).

## 5. Metrik (dari output notebook)

| Evaluasi | R² | MAE (mg/L) | RMSE (mg/L) |
|---|---|---|---|
| Locked test (random split, n=8.321) | **0,4244** | 3,0011 | 4,0794 |
| Validation | 0,4129 | 3,0442 | 4,1463 |
| Baseline rata-rata | -0,0002 | 4,4871 | 5,3774 |
| Baseline regresi linear (MLR) | 0,2721 | 3,5662 | 4,5874 |

Leave-one-source-out (sumber data belum pernah dilihat): fishpond **-2,3424**, aquaponds **-0,3246**, smart_aquaculture **-1,3961**. Uji lintas domain (sungai air dingin, suhu 10-21 °C): **-238,25**.

Data: 55.472 baris bersih (train 38.830 / val 8.321 / test 8.321) dari 3 sumber (aquaponds 47.962; smart_aquaculture 5.357; fishpond_multiclass 2.153). Hyperparameter terbaik: `n_estimators=300, learning_rate=0.03, max_depth=8, subsample=0.85, colsample_bytree=0.8, min_child_weight=3`.
Ukuran pipeline ±3,4 MB; latensi 1 baris ±8,9 ms (Python, Colab).

## 5b. Batasan (WAJIB dibaca)

1. R² hanya 0,42 pada split acak dan **negatif** pada sumber data baru → estimasi bisa lebih buruk daripada menebak rata-rata pada kolam/sensor baru.
2. `month_sin` + `month_cos` ≈ 68% feature importance: model sebagian besar "mengenali" musim/sumber data. Dua dari tiga dataset latih hanya mencakup sebagian kecil kalender.
3. Tanpa turbidity (kasus ESP32), input efektif hanya suhu, pH, dan waktu.
4. Tidak mendeteksi lonjakan alga/fotosintesis langsung.
5. Perlu kalibrasi per lokasi dan validasi terhadap DO meter sebelum dipakai sebagai dasar keputusan.

## 6. Uji penerimaan (acceptance)

1. Model termuat via `app.compat` tanpa error.
2. Input contoh `temp_c=28.0, ph=7.2, turbidity_ntu=null, timestamp=2026-01-01T14:00:00` menghasilkan float dalam 0-25.
3. **Parity dengan notebook:** hasilkan berkas emas di Colab (sel di bawah), simpan sebagai `samples/do_golden_samples.csv`, lalu pastikan selisih prediksi service < 1e-6.
4. `turbidity_ntu=null` dan `turbidity_ntu=25` sama-sama berjalan tanpa error.

Sel Colab untuk berkas emas (setelah semua sel notebook dijalankan):

```python
gold = X_test.iloc[:20].copy()
gold["expected_do_mgl"] = best_model.predict(X_test.iloc[:20])
gold.to_csv("do_golden_samples.csv", index=False)   # kolom = 7 kolom input + expected_do_mgl
```

## 7. Catatan implementasi untuk agent

- Kode sumber: notebook `RonaAir_DO_XGBoost_Final.ipynb`, "CELL 5-6" (adapter dataset), "CELL 10-12" (feature engineering), "CELL 26-28" (penyimpanan).
- Jangan mengubah `RAW_INPUT_COLS`, rumus fitur, atau imputasi. Jika ingin mengubah fitur, latih ulang dan simpan sebagai `v2`.
- Validasi rentang input memakai `app.compat.PHYS_BOUNDS`.
