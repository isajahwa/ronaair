# MODEL_SPEC - `risk_fusion` (Decision Fusion & Risk AI)

| | |
|---|---|
| Sumber | `RonaAir_Decision_Fusion_Risk_AI.ipynb` (`MODEL_VERSION = "ronair-risk-ai-1.0.0"`) |
| Jenis | **Rule engine** (produksi) + model ML benchmark (eksperimental) |
| `decision_source` | `RULE_ENGINE_LEVEL_1` |
| Endpoint rencana | `POST /assess` |
| Peran | Keputusan akhir: `risk_status`, faktor pendukung, kualitas data, rekomendasi |
| Status | Aktif, **seluruh threshold & rekomendasi PROVISIONAL** (tidak ada yang VALIDATED) |

Notebook ini **tidak melatih ulang** model CV maupun pH-strip; ia menyusun lapisan keputusan di atasnya.
Sistem ini adalah *early warning* dan *decision support*: bukan detektor spesies alga, bukan pengukur toksin, bukan pengganti laboratorium.

## 1. Artefak (di `v1/`)

| File | Status |
|---|---|
| `risk_rules.json`, `recommendation_rules.json`, `risk_input_schema.json`, `risk_output_schema.json` | WAJIB |
| `risk_cost_matrix.json`, `risk_model_card.md`, `risk_model_report.md` | PENDUKUNG |
| `risk_model.joblib`, `risk_preprocessor.joblib`, `risk_model_parameters.json`, `risk_feature_schema.json`, `risk_model_metadata.json` | OPSIONAL (benchmark) |

Aturan hidup di **`risk_rules.json`**, bukan di kode: ubah ambang lewat file itu. Tabel di bawah adalah ringkasannya (`verify_artifacts.py --load` membandingkan keduanya).

## 2. Kontrak input (`risk_input_schema.json`)

Semua field boleh `null`; mesin menurunkan kualitas data alih-alih menebak.

| Field | Tipe | Satuan | Wajib | Rentang plausibel | Sumber |
|---|---|---|---|---|---|
| `water_temp` | float | °C | **Ya** | 0 - 45 | ESP32 |
| `ph_sensor` | float | pH | **Ya** | 0 - 14 | ESP32 |
| `do_est` | float | mg/L | Tidak* | 0 - 25 | `do_soft_sensor` (ESTIMATED) |
| `visual_score` | float | **0-1** | Tidak* | 0 - 1 | `cv_water_visual.visual_score ÷ 100` |
| `visual_condition` | string | - | Tidak | - | CV; hanya untuk penjelasan |
| `image_quality` | string | OK/FAIL | Tidak | - | Quality gate foto; FAIL → `visual_score` diabaikan |
| `ph_visual_est` | float | pH | Tidak | 0 - 14 | `ph_strip` |
| `ec_value` | float | µS/cm | Tidak | 0 - 100000 | ESP32 |
| `tds_ppm` | float | ppm | Tidak | 0 - 50000 | ESP32 (turunan EC) |
| `hour` | int | 0-23 | Tidak | 0 - 23 | jam perangkat |

\* Minimal salah satu dari `do_est` atau `visual_score` harus ada.

## 3. Logika (`rule_engine` di notebook, "Cell 16")

```
1. Jika ph_visual_est & ph_sensor ada:  ph_difference = |ph_visual_est − ph_sensor|
2. Plausibilitas: nilai di luar plausibility_ranges → dibuang (None) + peringatan "kemungkinan sensor fault"
3. OOD: nilai di luar [p01, p99] empirical_operating_envelope → catatan OOD
4. Kualitas data:
     missing_required  = [water_temp, ph_sensor] yang None
     missing_highvalue = [do_est, visual_score] yang None
     image_failed      = image_quality ∈ {FAIL, BAD, POOR}
     INSUFFICIENT_EVIDENCE bila missing_required ATAU (kedua high-value kosong)
     DEGRADED             bila ada peringatan ATAU image_failed ATAU salah satu high-value kosong
     POSSIBLE_OUT_OF_DISTRIBUTION bila ada catatan OOD
     OK                   selain itu
5. INSUFFICIENT_EVIDENCE → berhenti (risk_status = INSUFFICIENT_EVIDENCE, tanpa rule)
6. Evaluasi semua rule; status = tingkat TERTINGGI di antara rule aktif (MAX_SEVERITY)
   NORMAL < WASPADA < SIAGA < DARURAT.  Jika tidak ada rule aktif → NORMAL.
```

Catatan dari notebook: `image_quality = FAIL` membuat `visual_score` diabaikan dan `data_quality` menjadi DEGRADED.

## 4. Rule (semua PROVISIONAL)

| ID | Parameter | Kondisi | Level | Catatan |
|---|---|---|---|---|
| R001 | `do_est` | < 2,0 mg/L | DARURAT | Hipoksia berat; berlaku pada **estimasi** → perlu konfirmasi sensor |
| R002 | `do_est` | < 3,0 mg/L | SIAGA | Stres pernapasan |
| R003 | `do_est` | < 5,0 mg/L | WASPADA | Di bawah kisaran nyaman umum |
| R010 | `ph_sensor` | < 5,5 | DARURAT | Asam ekstrem |
| R011 | `ph_sensor` | > 9,5 | DARURAT | Basa ekstrem |
| R012 | `ph_sensor` | < 6,5 | SIAGA | |
| R013 | `ph_sensor` | > 9,0 | SIAGA | |
| R020 | `water_temp` | > 34,0 °C | SIAGA | Kelarutan O₂ turun, metabolisme naik |
| R021 | `water_temp` | < 20,0 °C | WASPADA | Nafsu makan turun (spesies tropis) |
| R030 | `visual_score` | ≥ 0,75 | SIAGA | Indikator visual saja |
| R031 | `visual_score` | ≥ 0,50 | WASPADA | Perubahan rona air |
| R040 | `ph_difference` | > 1,0 | WASPADA | Sinyal **kualitas data** (drift sensor / foto buruk), bukan bahaya biologis |

Beberapa rule bisa aktif bersamaan (mis. pH 5,0 memicu R010 dan R012); status akhir = tertinggi.

## 5. Kontrak output (`risk_output_schema.json`)

```json
{
  "risk_status": "SIAGA",
  "supporting_factors": ["[R002] do_est=2.4 < 3.0 mg/L -> SIAGA"],
  "fired_rules": ["R002", "R003"],
  "data_quality": "OK",
  "out_of_distribution_notes": [],
  "recommendations": [
    {"id": "...", "action": "...", "priority": 1, "contraindication": "...",
     "recheck_after_minutes": 0, "validation_status": "PROVISIONAL"}
  ],
  "explanation": "APA YANG TERJADI? ... MENGAPA? ... KAPAN PERIKSA ULANG? ...",
  "model_version": "ronair-risk-ai-1.0.0",
  "decision_source": "RULE_ENGINE_LEVEL_1",
  "timestamp": "2026-01-01 14:00:00"
}
```

- `risk_status` ∈ {NORMAL, WASPADA, SIAGA, DARURAT, INSUFFICIENT_EVIDENCE}
- `data_quality` ∈ {OK, DEGRADED, POSSIBLE_OUT_OF_DISTRIBUTION, INSUFFICIENT_EVIDENCE}
- **`risk_probability` sengaja tidak ada.** Model ML dilatih pada label turunan aturan, sehingga probabilitasnya tidak terkalibrasi terhadap risiko nyata dan menyesatkan bila ditampilkan sebagai "peluang bahaya".
- Rekomendasi: `recommend()` memilih per `risk_status` lalu menambah rekomendasi pemicu-spesifik (`trigger_specific`) berdasarkan rule aktif, urut `priority`. Semuanya PROVISIONAL.
- Opsional `ml_benchmark` (eksperimental) - lihat bagian 7. Jangan dijadikan keputusan.

## 6. Kasus uji deterministik

Diturunkan langsung dari aturan di atas (kecuali dinyatakan lain, `data_quality` juga bergantung pada `empirical_operating_envelope` di `risk_rules.json`).

| # | Input (ringkas) | Hasil yang diharapkan |
|---|---|---|
| 1 | `water_temp=24.3, ph_sensor=7.5, tds_ppm=330`, tanpa `do_est` & `visual_score` | `INSUFFICIENT_EVIDENCE` (tidak ada bukti oksigen maupun visual) |
| 2 | `water_temp=31.2, ph_sensor=8.1, tds_ppm=410, ec_value=820, do_est=2.4, visual_score=0.82, ph_visual_est=8.0, image_quality=OK, hour=5` | `SIAGA`; aktif `R002, R003, R030, R031` |
| 3 | `water_temp=25.0, ph_sensor=15.8` | `ph_sensor` dibuang (di luar 0-14) → `INSUFFICIENT_EVIDENCE` + peringatan sensor fault |
| 4 | semua `null` | `INSUFFICIENT_EVIDENCE` |
| 5 | `water_temp=27, ph_sensor=5.0, do_est=6.5, visual_score=0.2` | `DARURAT`; aktif `R010, R012` |
| 6 | `water_temp=27, ph_sensor=7.2, do_est=6.5, visual_score=0.2` | `NORMAL` (tidak ada rule aktif) |
| 7 | `water_temp=27, ph_sensor=7.2, do_est=6.5, ph_visual_est=8.5` | `WASPADA` (R040: selisih 1,3 > 1,0) |
| 8 | `water_temp=27, ph_sensor=7.2, do_est=6.5, visual_score=63.4` (lupa ÷100) | `visual_score` dibuang (di luar 0-1) dengan peringatan; `NORMAL` dengan `data_quality=DEGRADED`. Uji regresi untuk kesalahan skala |

Kasus 1-4 adalah demonstrasi di notebook ("Cell 28"). Kedelapan kasus tersedia sebagai data di **`../../samples/fusion_cases.json`** (hasilnya sudah dieksekusi dengan salinan logika `rule_engine`; `expected_data_quality` dihitung tanpa envelope OOD, jadi cocokkan `risk_status` dan `fired_rules` secara ketat dan `data_quality` secara longgar).

## 7. Model ML benchmark (opsional, eksperimental)

- `DecisionTree_d6` pada feature set `A_sensor_only`: `water_temp, ph_sensor, ec_value, tds_ppm, do_est`.
- Dilatih pada dataset D2 (`fishpond_dataset_multiclass_2153`, 2.153 baris; label turunan aturan turbidity).
- Hasil test (n=431): macro-F1 0,9928; balanced accuracy 0,9929; accuracy 0,9930; high-risk (SIAGA+DARURAT) recall 0,9941, precision 1,0000, false negative 1 dari 169; kesalahan DARURAT→NORMAL: 0.
- **Mengapa skornya menyesatkan:** label D2 direproduksi 1,0000 dari satu parameter → model meniru aturan turbidity, bukan risiko biologis. Kesepakatan rule engine vs label D2 hanya 0,7622.
- Validasi eksternal: **tidak tersedia** (D1 kosong; D3 semantik target berbeda; D4 tanpa label/DO/turbidity).
- Bila ditampilkan, harus berlabel "EKSPERIMENTAL" dan **tidak** memengaruhi `risk_status`.

## 8. Uji penerimaan

1. `python scripts/verify_artifacts.py --load --model risk_fusion`: 12 rule termuat, cocok dengan `models.yaml`.
2. Kedelapan kasus di bagian 6 lolos sebagai unit test otomatis.
3. Mengubah ambang di `risk_rules.json` mengubah perilaku tanpa mengubah kode.
4. Respons tidak pernah berisi probabilitas risiko.

## 9. Catatan implementasi untuk agent

- Kode acuan di notebook: `rule_engine` ("Cell 16"), `recommend`/`explain`/`predict_risk` ("Cell 27-28"), kontrak I/O ("Cell 29"). Salin logikanya ke `app/fusion.py` dan **baca aturan dari `risk_rules.json`** (jangan menulis ulang ambang di kode).
- `RiskEngine.kt` adalah padanan Kotlin: hanya referensi.
- Semua ambang dan rekomendasi berstatus PROVISIONAL; UI wajib menandainya dan menampilkan `data_quality`.
- Bila model versi baru (`v2`) dibuat, catat `model_version` di tabel hasil lewat file migrasi SQL baru.
