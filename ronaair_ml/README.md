# ronaair_ml - lapisan model AI RonaAir

Folder ini menyimpan **semua model AI RonaAir (hasil training di Colab), spesifikasinya, dan registry-nya**, serta akan menjadi tempat layanan inferensi Python (FastAPI) yang dipanggil oleh backend Go.

```
Flutter (ronaair_app) ──HTTP──► Go (ronaair_backend :8080) ──HTTP──► ronaair_ml (FastAPI :8000)
                                        │                                   │
                                        ▼                                   ▼
                                  MySQL "ronaair"                    model .joblib / .tflite / .json
```

> RonaAir adalah **sistem peringatan dini dan pendukung keputusan** untuk kualitas air kolam ikan air tawar.
> Bukan detektor spesies alga, bukan pengukur toksin, bukan pengganti laboratorium.

## Status saat ini

| Bagian | Status |
|---|---|
| Registry (`models.yaml`), spesifikasi model, daftar artefak, catatan integrasi | ✅ Tersedia |
| Skrip bantu (`verify_artifacts`, `extract_cv_labels`, `inspect_tflite`, `print_env_versions`) dan shim `app/compat.py` | ✅ Tersedia dan diuji |
| **File model hasil training** (`.joblib`, `.tflite`, `.json`) | ⬜ **Belum disalin** - lihat `ARTIFACTS.md` |
| Layanan FastAPI (`app/main.py`, dst.) | ⬜ Belum dibuat (tahap berikutnya, bisa dikerjakan OpenCode) |
| Pin versi library (`requirements.txt`) | ⬜ Menunggu `env_versions.json` dari Colab |

## Empat model

| ID | Fungsi | Artefak utama | Status | Hal terpenting |
|---|---|---|---|---|
| `do_soft_sensor` | Estimasi DO (mg/L) dari suhu, pH, (turbidity), waktu | `ronaair_do_xgboost_final.joblib` | Aktif, **terbatas** | R² 0,42; negatif pada sumber data baru. Wajib `app.compat`. Tampilkan "Estimated DO". |
| `ph_strip` | Estimasi pH dari foto pH strip | `model_coefficients.json` | Aktif, **belum diverifikasi** | Notebook tanpa output eksekusi. Model final diduga PolynomialRidge2 (24 fitur). |
| `cv_water_visual` | Skrining visual air: kelas + Visual Score | `ronair_cv_classifier.tflite` | Aktif, **terbatas** | 31 kelas label-folder; macro F1 0,15. `visual_score` dihitung OpenCV (0-100). |
| `risk_fusion` | Keputusan akhir: NORMAL/WASPADA/SIAGA/DARURAT | `risk_rules.json` | Aktif, **PROVISIONAL** | Produksi = rule engine, bukan ML. Semua ambang belum divalidasi. |

Detail tiap model: `models/<id>/MODEL_SPEC.md`. Ringkasan mesin-terbaca: `models.yaml`.

## Struktur folder

```
ronaair_ml/
├─ README.md                  ← dokumen ini
├─ ARTIFACTS.md               ← daftar file hasil training: asal, tujuan, status
├─ INTEGRATION_NOTES.md       ← temuan penting, keputusan terbuka, aturan untuk AGENTS.md
├─ models.yaml                ← registry (versi aktif, artefak, kontrak, pemetaan fusion)
├─ requirements.txt           ← dependensi (pin versi = TODO)
├─ .gitignore
├─ app/
│   └─ compat.py              ← shim memuat pipeline DO (kelas kustom dari notebook)
├─ scripts/
│   ├─ verify_artifacts.py    ← cek artefak sudah disalin & valid
│   ├─ extract_cv_labels.py   ← buat labels.json dari model_metadata.json
│   ├─ inspect_tflite.py      ← cek input/output TFLite, uji 1 gambar
│   └─ print_env_versions.py  ← jalankan di Colab untuk mencatat versi library
├─ models/
│   ├─ do_soft_sensor/   MODEL_SPEC.md   v1/
│   ├─ ph_strip/         MODEL_SPEC.md   v1/
│   ├─ cv_water_visual/  MODEL_SPEC.md   v1/labels.provisional.json
│   └─ risk_fusion/      MODEL_SPEC.md   v1/
├─ samples/
│   └─ fusion_cases.json      ← 8 kasus uji deterministik untuk risk_fusion
└─ training/notebooks/        ← taruh 4 notebook sumber di sini (di-ignore Git)
```

Setelah service dibuat, akan bertambah `app/main.py`, `app/registry.py`, `app/routers/`, `app/fusion.py`, dan `tests/`.

## Langkah menyiapkan

1. **Salin artefak** dari hasil training ke `models/<id>/v1/` sesuai tabel di `ARTIFACTS.md` (file berstatus WAJIB dan PENDUKUNG).
2. **Catat versi library** - unggah `scripts/print_env_versions.py` ke Colab (runtime yang sama dengan training), jalankan `%run print_env_versions.py`, simpan `env_versions.json` ke folder ini, lalu ganti baris `TODO-PIN` di `requirements.txt`.
3. **Buat labels CV resmi:** `python scripts/extract_cv_labels.py` (butuh `model_metadata.json` CV sudah disalin).
4. **Periksa:**
   ```bash
   pip install pyyaml
   python scripts/verify_artifacts.py            # artefak wajib ada & JSON valid
   python scripts/verify_artifacts.py --load     # + uji muat model (library harus terpasang)
   python scripts/inspect_tflite.py              # kontrak input/output model CV
   ```
5. **Bangun berkas emas di Colab** (sel tiap `MODEL_SPEC.md`, bagian "Uji penerimaan") dan simpan ke `samples/` untuk uji parity.
6. **Putuskan hal terbuka** di `INTEGRATION_NOTES.md` (D1-D9), terutama skala `visual_score`, perlakuan `do_est`, dan pemetaan `image_quality`.
7. Salin bagian "Aturan untuk AGENTS.md" dari `INTEGRATION_NOTES.md` ke `AGENTS.md` di folder induk `ronaair/`.

## Menyambungkan lewat OpenCode

Jalankan `opencode` dari **folder induk** `ronaair/` (yang berisi `ronaair_app`, `ronaair_backend`, `ronaair_ml`), lakukan `git commit` + `mysqldump` dulu, dan bekerja di cabang baru. Salin 4 notebook ke `training/notebooks/` agar agent bisa membaca kode sumbernya.

**Urutan yang disarankan** (dari yang paling mudah diuji ke yang paling berat):
`risk_fusion` → `do_soft_sensor` → `ph_strip` → `cv_water_visual` → endpoint Go + migrasi DB → Flutter.

**Tahap 1 - rencana (mode `plan`, tanpa mengubah file):**

```
Baca ronaair_ml/README.md, models.yaml, INTEGRATION_NOTES.md, semua models/*/MODEL_SPEC.md, dan samples/fusion_cases.json.
Pelajari juga ronaair_backend (Go + MySQL) dan ronaair_app (Flutter).
Rencanakan integrasi keempat model: service FastAPI di ronaair_ml, endpoint Go yang memanggilnya, perubahan skema database (file migrasi BARU), dan layar Flutter.
Untuk tiap model sebutkan endpoint, tabel tujuan, dan risiko. Sebutkan pula pertanyaan yang belum terjawab dari INTEGRATION_NOTES (D1-D9).
JANGAN mengubah file apa pun. Tunggu persetujuan saya.
```

**Tahap 2 - contoh untuk model pertama (mode `build`):**

```
Buat kerangka service FastAPI di ronaair_ml/app: main.py, registry.py (membaca models.yaml), GET /health dan GET /models.
Lalu implementasikan risk_fusion: app/fusion.py yang membaca models/risk_fusion/v1/risk_rules.json dan recommendation_rules.json (jangan menulis ulang ambang di kode), endpoint POST /assess, dan tests/ yang menjalankan semua kasus di samples/fusion_cases.json.
Ikuti models/risk_fusion/MODEL_SPEC.md. Jangan menyentuh ronaair_app atau ronaair_backend. Beri perintah untuk menjalankan tes.
```

Ulangi pola yang sama per model (satu model per putaran, uji sebelum lanjut, `git commit` di setiap tahap). Untuk `do_soft_sensor` sebutkan wajib memakai `app.compat`; untuk `cv_water_visual` sebutkan bahwa `visual_score` harus dihitung dengan port kode OpenCV dari notebook CV.

## Dokumen terkait

- `ARTIFACTS.md` - file apa yang disalin, dari mana, ke mana.
- `INTEGRATION_NOTES.md` - temuan kritis (skala `visual_score`, 31 kelas CV, validitas DO, status PROVISIONAL) dan keputusan terbuka.
- `models/<id>/MODEL_SPEC.md` - kontrak input/output, metrik, batasan, uji penerimaan.
