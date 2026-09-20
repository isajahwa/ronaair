# ARTIFACTS - daftar file hasil training yang dipakai RonaAir

Dokumen ini menjawab: **file mana dari hasil training (Colab) yang harus disalin ke `ronaair_ml/`, dari mana asalnya, dan ke mana tujuannya.**
Daftar diturunkan dari kode dan output eksekusi 4 notebook. Nama file dipertahankan persis seperti hasil notebook.

**Legenda status**

| Status | Arti |
|---|---|
| **WAJIB** | Dibutuhkan saat runtime / kontrak. Tanpa ini layanan tidak boleh dijalankan. `verify_artifacts.py` gagal bila hilang. |
| PENDUKUNG | Metadata, metrik, dokumentasi. Sangat disarankan ada. |
| OPSIONAL | Berguna tetapi tidak dipakai pada jalur utama. |
| CADANGAN | Dipakai hanya jika jalur utama tidak bisa. |
| REFERENSI | Baca saja; jangan dijalankan/dipakai langsung. |
| TIDAK DIPAKAI | Tidak perlu disalin ke repo. |

Tujuan semua file: `ronaair_ml/models/<id_model>/v1/` (datar, tanpa subfolder), kecuali disebut lain.

---

## 1. `do_soft_sensor` - `RonaAir_DO_XGBoost_Final.ipynb`

Asal di Colab: `/content/RonaAir_XGBoost_Final/`  ->  Tujuan: `models/do_soft_sensor/v1/`

| File | Status | Catatan |
|---|---|---|
| `ronaair_do_xgboost_final.joblib` | **WAJIB** | sklearn Pipeline: `AquacultureFeatureEngineer` -> `StandardScaler` -> `XGBRegressor`. ±3,4 MB. Muat lewat `app.compat.load_do_pipeline`. |
| `feature_schema.json` | **WAJIB** | Urutan 7 kolom input + catatan fitur siklus. |
| `model_metadata.json` | PENDUKUNG | Hyperparameter, metrik (random split, leave-one-source-out), bounds fisik, sumber data. |
| `model_card.md` | PENDUKUNG | |
| `test_inference.py` | REFERENSI | Path Colab ter-hardcode dan tidak mendefinisikan kelas kustom, jadi gagal di luar notebook. |
| `executive_decision_report.txt` | REFERENSI | Narasi untuk juri. |

## 2. `ph_strip` - `RonaAir_pH_Strip_AI_Colab.ipynb`

Asal di Colab: `/content/ronair_ph/deployment/` (salinan di `models/` identik)  ->  Tujuan: `models/ph_strip/v1/`

| File | Status | Catatan |
|---|---|---|
| `model_coefficients.json` | **WAJIB** | JSON murni (scaler + polinomial derajat 2 + koefisien). Tidak butuh sklearn saat inferensi. Parity vs sklearn diuji notebook (< 1e-6). |
| `feature_schema.json` | **WAJIB** | Urutan resmi fitur + statistik fitur. |
| `preprocessing_config.json` | **WAJIB** | Aturan ROI, quality gate, rentang pH valid. |
| `model_metadata.json` | **WAJIB** | Model final, metrik test, rentang pH latih/validasi/test, versi library. |
| `model_card.md` | PENDUKUNG | |
| `final_summary.json` | PENDUKUNG | Asal: `results/final_summary.json`. |
| `final_model.joblib` | CADANGAN | Hanya bila versi scikit-learn sama dengan training. |
| `scaler.joblib` | TIDAK DIPAKAI | Scaler sudah ada di `model_coefficients.json`. |
| `PhPredictor.kt` | TIDAK DIPAKAI | Untuk Android native; Flutter+Go memakai layanan Python. |
| `test_inference.py` | REFERENSI | Smoke test paket deployment. |
| `RonaAir_pH_AI_Deployment.zip`, `RonaAir_pH_AI_Artifacts.zip` | - | Paket dari notebook; cukup ambil file di atas dari dalam ZIP. |

> **Perhatian:** file `.ipynb` yang Anda unggah **tidak berisi output eksekusi**. Model final yang tercatat di notebook fusion adalah `PolynomialRidge2` / `COMBINED_ALL` (24 fitur), tetapi itu harus dikonfirmasi dari `model_metadata.json` hasil run Anda. Bila ternyata `KerasMLP_16_8_1`, jalur deploy-nya berbeda (`final_model.tflite` + `scaler.joblib`), dan `models.yaml` perlu diperbarui.

## 3. `cv_water_visual` - `Copy_of_RonaAir_CV_RGB_DeepLearning_FINAL.ipynb`

Asal di Colab: `/content/RonaAir_CV/04_models/`, `05_outputs/`, `06_configs/`  ->  Tujuan: `models/cv_water_visual/v1/`

| File | Asal | Status | Catatan |
|---|---|---|---|
| `ronair_cv_classifier.tflite` | `04_models/` | **WAJIB** | MobileNetV3-Small + Dropout + Dense softmax (31 kelas), kuantisasi dynamic, 1,13 MB. |
| `model_metadata.json` | `04_models/` (juga di `05_outputs/`) | **WAJIB** | Sumber resmi daftar kelas (`supervised_evaluation.classes`), metrik, definisi Visual Score. |
| `android_deployment_runtime.json` | `06_configs/` | PENDUKUNG | input_shape, class_names, preprocessing. |
| `classification_report.csv` | `05_outputs/` | PENDUKUNG | Metrik per kelas. |
| `confusion_matrix.csv` | `05_outputs/` | PENDUKUNG | Dibutuhkan untuk menghitung akurasi kelompok (lihat INTEGRATION_NOTES #3). |
| `label_mapping_table.csv` | `05_outputs/` | PENDUKUNG | Bukti audit pemetaan label. |
| `ronair_cv_classifier_int8.tflite` | `04_models/` | OPSIONAL | **Jangan dipakai dulu**: inferensinya gagal di Colab (XNNPACK error). |
| `ronair_mobilenetv3_small_feature_extractor.tflite` | `04_models/` | OPSIONAL | Embedding; tidak dibutuhkan fusion. |
| `ronair_cv_classifier.keras` | `04_models/` | OPSIONAL | Cadangan untuk konversi/retraining (9,15 MB). |
| `ronair_mobilenetv3_small_feature_extractor.keras` | `04_models/` | TIDAK DIPAKAI | |
| `best_head.keras`, `best_finetuned.keras` | `04_models/` | TIDAK DIPAKAI | Checkpoint training. |
| `per_image_output.csv`, `export_results.csv`, `deployment_readiness*.csv` | `05_outputs/` | OPSIONAL | Analisis tambahan. |

Setelah menyalin `model_metadata.json`, jalankan `python scripts/extract_cv_labels.py` untuk membuat `labels.json` resmi (file `labels.provisional.json` yang sudah ada hanyalah cadangan sementara).

## 4. `risk_fusion` - `RonaAir_Decision_Fusion_Risk_AI.ipynb`

Asal: root output notebook (`models/`, `configs/`, `deployment/`, `results/`)  ->  Tujuan: `models/risk_fusion/v1/` (datar)

| File | Asal | Status | Catatan |
|---|---|---|---|
| `risk_rules.json` | `configs/` | **WAJIB** | 12 rule (R001-R040), agregasi MAX_SEVERITY, plausibility ranges, envelope operasional empiris. |
| `recommendation_rules.json` | `configs/` = `deployment/` | **WAJIB** | Rekomendasi per status (PROVISIONAL). |
| `risk_input_schema.json` | `deployment/` | **WAJIB** | Kontrak input (semua field boleh null). |
| `risk_output_schema.json` | `deployment/` | **WAJIB** | Kontrak output; `risk_probability` sengaja tidak ada. |
| `risk_cost_matrix.json` | `configs/` | PENDUKUNG | |
| `risk_model_card.md` | `deployment/` | PENDUKUNG | |
| `risk_model_report.md` | `results/` | PENDUKUNG | |
| `risk_model.joblib` | `models/` | OPSIONAL (benchmark) | DecisionTree_d6 pada 5 fitur sensor. **Bukan** keputusan produksi. |
| `risk_preprocessor.joblib` | `models/` | OPSIONAL (benchmark) | |
| `risk_model_parameters.json` | `models/` | OPSIONAL (benchmark) | Ekspor native pohon keputusan. |
| `risk_feature_schema.json`, `risk_model_metadata.json` | `models/` | OPSIONAL (benchmark) | |
| `RiskEngine.kt` | `deployment/` | TIDAK DIPAKAI | Rule engine Kotlin; hanya referensi logika. |
| `results/*.csv`, `results/figures/`, `dataset_audit.json` dll. | `results/` | OPSIONAL | Bukti audit; simpan di luar repo bila berat. |

---

## Cara menyalin (ringkas)

1. Di Colab, unduh: ZIP deployment/artifacts tiap notebook (atau file-file di tabel).
2. Salin file berstatus **WAJIB** dan **PENDUKUNG** ke folder tujuan masing-masing.
3. Dari `ronaair_ml/`, jalankan:
   ```bash
   pip install pyyaml
   python scripts/verify_artifacts.py            # cek keberadaan & JSON valid
   python scripts/verify_artifacts.py --load     # + uji muat model (butuh library terpasang)
   python scripts/verify_artifacts.py --checksums   # catat SHA-256 ke CHECKSUMS.txt
   ```
4. Jalankan `scripts/print_env_versions.py` di Colab dan simpan `env_versions.json` (untuk pin versi di `requirements.txt`).

## Yang BUKAN artefak (jangan disalin ke repo)

- Dataset mentah: dua ZIP Google Drive untuk CV (6,0 GB dan 352 MB), lima CSV untuk DO, tiga file untuk pH, dataset D1-D4 untuk fusion.
- Cache fitur besar (`visual_features*.csv` ±33 MB, `data_split.csv`, `quality_report.csv`), kecuali dibutuhkan untuk reproduksi.
