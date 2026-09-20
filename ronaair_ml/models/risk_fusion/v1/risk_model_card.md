# RonaAir Risk Model Card

* **Model version**: ronair-risk-ai-1.0.0
* **Notebook version**: 1.0.0
* **Generated**: 2026-09-18 01:24:58

## Purpose

Menyediakan lapisan **Decision Fusion / Risk AI** untuk RonaAir: menggabungkan bukti sensor
dan bukti visual menjadi status risiko (NORMAL / WASPADA / SIAGA / DARURAT) beserta penjelasan
dan rekomendasi tindakan.

## Intended use

* Early warning dan decision support bagi pembudidaya ikan air tawar.
* Berjalan offline di Android.

**Bukan untuk**: identifikasi spesies alga, pengukuran konsentrasi toksin, konfirmasi HAB
definitif, pengganti laboratorium, atau sistem medis.

## Inputs

Lihat `deployment/risk_input_schema.json`. Ringkas: `visual_score`, `visual_condition`,
`image_quality`, `ph_visual_est`, `ph_sensor`, `water_temp`, `ec_value`, `tds_ppm`,
`do_est` (**Estimated DO**, bukan Measured DO), `hour`.

## Outputs

Lihat `deployment/risk_output_schema.json`. Ringkas: `risk_status`, `supporting_factors`,
`fired_rules`, `data_quality`, `recommendations`, `explanation`, `model_version`, `timestamp`.

`risk_probability` **tidak** diekspor karena label pelatihan bersifat turunan aturan, sehingga
probabilitas tidak terkalibrasi terhadap risiko dunia nyata.

## Datasets

| Dataset | Peran | Catatan kunci |
|---|---|---|
| Aquaponds (selected columns) | NOT SUITABLE | 0 baris berisi data — file hanya header |
| fishpond_dataset_multiclass_2153 | Rule-emulation benchmark | label tereproduksi 1.0000 dari `orp_mV` saja |
| Data_Model_IoTMLCQ_2024 | Reference only | Health Status identik 1:1 dengan Thermal Risk Index; Low Oxygen Alert konstan; kualitas air terinterpolasi |
| Aquaponic Fish Pond IoT | Auxiliary | 505,730 baris sensor nyata; tanpa label, tanpa DO; varian "filtered" bersifat sirkular |

## Label types

* Dataset pelatihan: **RULE-DERIVED (single-parameter threshold)** — bukan ground truth biologis.
* Tidak ada dataset yang menyediakan outcome ikan yang terobservasi secara independen.

## Training strategy

* Dataset: `D2_FISHPOND_MULTICLASS`
* Split: **stratified_random (LAST RESORT)** (train 1290 /
  validation 431 / test 431)
* Group split tidak mungkin: tidak ada pond/site ID di dataset mana pun.
* CV: `TimeSeriesSplit(n_splits=4)` pada train saja.
* Class imbalance: `class_weight="balanced"`; tanpa oversampling.
* Test set **dikunci**: tidak dipakai untuk seleksi fitur, tuning, maupun seleksi model.

## Validation

* Internal: validation split kronologis + CV temporal.
* **External validation: EXTERNAL VALIDATION NOT AVAILABLE** — semantik target antar dataset tidak
  kompatibel, dan dua dataset lain tidak memiliki label yang sebanding. Notebook tidak memalsukan
  external validation dengan menggabungkan dataset.

## Metrics

Model final: **DecisionTree_d6** pada feature set **A_sensor_only**.

| Metrik (test) | Nilai |
|---|---|
| Macro F1 | 0.9928 |
| Balanced Accuracy | 0.9929 |
| Accuracy | 0.9930 |
| Weighted F1 | 0.9930 |

## High-risk performance

| Metrik (test) | Nilai |
|---|---|
| HighRisk Recall (SIAGA+DARURAT) | 0.9941 |
| HighRisk Precision | 1.0000 |
| HighRisk F1 | 0.9970 |
| False negative risiko tinggi | 1 |
| DARURAT diprediksi NORMAL | 0 |
| Rata-rata severity gap | 0.0023 |

**Angka-angka ini mengukur kemampuan model meniru aturan threshold dataset, bukan kemampuan
memprediksi risiko biologis.**

## Limitations

* Label pelatihan adalah turunan aturan; model hanya mereproduksi logika keputusan tersebut.
* Dataset pelatihan sangat mungkin sintetis (timestamp di masa depan, grid sampling sempurna,
  batas kelas tidak tumpang tindih).
* Tidak ada pond/site ID -> generalisasi antar kolam tidak terukur.
* Tidak ada citra di dataset mana pun -> kanal visual RonaAir tidak tervalidasi terhadap sensor.
* `ph_visual_est` dan `ph_difference` tidak dapat dievaluasi (SET D tidak dapat dinilai).
* `do_est` adalah estimasi; rule DO belum divalidasi terhadap DO meter.
* Seluruh threshold dan seluruh rekomendasi berstatus **PROVISIONAL**.

## Domain shift

Distribusi antar dataset berbeda nyata (lihat `results/domain_shift_report.csv`). Dataset
aquaponics memiliki kimia air yang berbeda dari kolam budidaya murni; dataset sintetis memiliki
rentang jauh lebih lebar daripada sensor lapangan nyata.

## Deployment

* Jalur produksi: **rule engine Level 1** (`deployment/RiskEngine.kt`), Kotlin murni, offline.
* Model ML: benchmark eksperimental; parameter diekspor ke
  `models/risk_model_parameters.json` (native-exportable = True).
* TFLite tidak dibuat — model final adalah model tabular kecil yang tidak memerlukannya.

## Recommendation scope

Rekomendasi berasal dari tabel rule deterministik (bukan LLM generatif), berstatus
**PROVISIONAL / NEEDS_EXPERT_VALIDATION**, dan tidak memuat angka tindakan spesifik tanpa SOP.

## Version

ronair-risk-ai-1.0.0

## Known risks

* **False negative**: rule fisiologis dapat melewatkan bahaya yang tidak tercermin pada pH/suhu/DO
  (mis. amonia, nitrit, penyakit) karena parameter itu tidak diukur RonaAir.
* **False positive**: sensor yang belum dikalibrasi atau foto berpencahayaan buruk dapat memicu
  alarm; karena itu status `DEGRADED` dan `INSUFFICIENT_EVIDENCE` disediakan.
* **Over-trust**: pengguna dapat menganggap status DARURAT sebagai diagnosis. UI harus selalu
  menampilkan status validasi PROVISIONAL.
