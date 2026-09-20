# RonaAir — Decision Fusion & Risk AI: Laporan Teknis

Dibangkitkan: 2026-09-18 01:24:58 | Notebook 1.0.0 | Model ronair-risk-ai-1.0.0

## 1. Ringkasan eksekutif

Audit terhadap empat dataset publik menunjukkan bahwa **tidak satu pun menyediakan dasar yang
cukup untuk Risk AI supervised yang dapat dipertahankan secara ilmiah**. Karena itu, sesuai
Section 61 master prompt, sistem yang dibangun adalah:

```
Rule-Based Risk Engine (PRODUKSI)
+ Evidence Fusion + Explanation + Recommendation Engine
+ ML classifier sebagai BENCHMARK EKSPERIMENTAL
```

## 2. Temuan audit yang menentukan keputusan

1. **Aquaponds**: file berisi 124 baris tetapi
   **0 baris berisi data**. Hanya header.
2. **fishpond_dataset_multiclass_2153**: label `class` dapat direproduksi
   **1.0000** hanya dari `orp_mV`.
   Batas kelas tidak tumpang tindih sama sekali. Baris dengan DO di bawah 3 mg/L (hipoksia berat)
   tersebar ke kelas non-darurat. Ini bukan ground truth biologis.
3. **Data_Model_IoTMLCQ_2024**: `Health Status` adalah fungsi 1:1 dari `Thermal Risk Index`
   (= threshold suhu ~28.00 C);
   `Low Oxygen Alert` konstan; hanya 360 observasi
   kualitas air unik pada 4383 baris karena interpolasi linier.
4. **Aquaponic IoT**: 505,730 baris sensor **nyata**, tetapi tanpa label,
   tanpa DO, tanpa turbidity. Varian "filtered" tereproduksi persis dengan membuang nilai di luar
   rentang optimal (retensi 0.2339) -> range-filter bias.

## 3. Perbandingan rule engine vs label dataset

Rule engine fisiologis RonaAir hanya sepakat 0.7622 dengan label
dataset D2. Ini bukan kegagalan rule engine: keduanya mengukur hal yang berbeda. Label D2
ditentukan turbidity; rule engine ditentukan DO, pH, dan suhu.

## 4. Ablation

| Feature_Set            | Model           |   Validation_Macro_F1 |   Validation_HighRisk_Recall |
|:-----------------------|:----------------|----------------------:|-----------------------------:|
| A_sensor_only          | RandomForest    |                1      |                       1      |
| B_visual_proxy_only    | DecisionTree_d3 |                0.9978 |                       0.9941 |
| C_sensor_plus_visual   | RandomForest    |                1      |                       1      |
| E_full_temporal_fusion | MLP_32_16       |                1      |                       1      |

Kenaikan skor saat proxy visual ditambahkan **bukan** bukti bahwa fusion menambah informasi.
Itu terjadi karena label memang didefinisikan dari parameter tersebut.

## 5. Model final

* Model: **DecisionTree_d6** @ **A_sensor_only**
* Test Macro-F1: 0.9928 | Balanced Accuracy: 0.9929
* HighRisk Recall: 0.9941
* **Interpretasi**: angka ini menunjukkan model berhasil meniru aturan threshold dataset.
  Angka ini **tidak** menunjukkan RonaAir siap memprediksi risiko di kolam Indonesia.

## 6. Performa model vs validitas dunia nyata (Section 59)

| Aspek | Status |
|---|---|
| Model performance pada dataset publik | Terukur, dilaporkan apa adanya |
| Validitas dunia nyata | **BELUM TERUJI** |
| External validation | EXTERNAL VALIDATION NOT AVAILABLE |
| Validasi kanal visual | Tidak mungkin — tidak ada citra di dataset mana pun |
| Validasi soft-sensor DO | Tidak mungkin — tidak ada pasangan DO terukur vs estimasi |

## 7. Langkah berikutnya

Lihat `results/ronair_missing_data_plan.csv`. Prioritas 1: foto + sensor bersinkron, label pakar,
outcome ikan terobservasi, dan DO terukur berpasangan.
