# INTEGRATION NOTES - hal yang harus diketahui sebelum menyambungkan model

Catatan ini berasal dari membaca kode **dan output eksekusi** keempat notebook. Angka berasal dari output notebook;
bila tidak ada outputnya, ditulis "tidak tersedia" (tidak dikarang).

## 0. Alur data satu sesi pemeriksaan

```
ESP32 (suhu, pH probe, EC, TDS) ─────────────────────────────┐
                                                              │  water_temp, ph_sensor, ec_value, tds_ppm, hour
Foto pH strip  ──► ph_strip ──► estimated_pH ──► ph_visual_est ┤
Foto air kolam ──► cv_water_visual ──► visual_score (0-100 → ÷100) ┤
                                  └──► predicted_class ──► visual_condition
suhu + pH + (turbidity) + waktu ──► do_soft_sensor ──► do_est ─┤
                                                              ▼
                                                        risk_fusion (RULE ENGINE)
                                                              ▼
              risk_status + supporting_factors + data_quality + recommendations (PROVISIONAL)
```

Flutter → Go → layanan Python (`ronaair_ml`). Go adalah satu-satunya pemanggil layanan Python.

---

## 1. Skala `visual_score` tidak cocok (0-100 vs 0-1)

- **Fakta:** notebook CV mendefinisikan Visual Score 0-100 (`compute_visual_score`). Rule engine di notebook fusion memakai `visual_score` skala **0-1** (ambang R030 ≥ 0,75 SIAGA; R031 ≥ 0,50 WASPADA; plausibility [0, 1]).
- **Dampak:** memasukkan mis. 63,4 langsung ke rule engine akan dianggap di luar rentang fisik: nilainya dibuang dengan peringatan "kemungkinan sensor fault" dan `data_quality` turun ke DEGRADED, sehingga kanal visual praktis tidak pernah dipakai. Nilai kecil (mis. 0,4 pada skala 0-100) akan salah dibaca sebagai skala 0-1.
- **Tindakan:** bagi 100 sebelum fusion (sudah tertulis di `models.yaml` → `pipeline.fusion_inputs.visual_score`).
- **Catatan kalibrasi:** rata-rata Visual Score dataset = 27,40 (min 0, maks 93,95). Ambang 50/75 di rule engine berstatus PROVISIONAL dan **belum pernah dikalibrasi terhadap skor CV** - anggap perlu ditinjau.

## 2. `visual_score` BUKAN keluaran model TFLite

- **Fakta:** Visual Score dihitung deterministik dari fitur warna OpenCV di area air:
  `VS = 100 × (0,35·green_chroma + 0,25·lab_green + 0,20·saturation + 0,20·density)`.
  Notebook fusion menuliskan sumbernya sebagai "CV model (ronair_cv_classifier.tflite)" - itu kurang tepat.
- **Dampak:** hanya memuat `.tflite` **tidak** menghasilkan `visual_score`.
- **Tindakan:** pindahkan ke layanan Python fungsi dari notebook CV: `detect_ronacard`, `calibrate_with_ronacard`, `extract_water_roi`, `extract_visual_features`, `compute_visual_score` (semua ada di sel definisi pertama notebook CV). Simpan notebooknya di `training/notebooks/` agar agent bisa membacanya.

## 3. Classifier CV punya 31 kelas dari label folder mentah

- **Fakta:** pemetaan label ke 4 kelas RonaAir hanya mencakup 0,22% gambar, sehingga notebook **kembali ke label folder mentah**. Hasilnya 31 kelas: 27 folder foto algal bloom Swedia per lokasi, `Kommunens_bilder` (isi tak terdokumentasi), `other`, `water_bad`, `water_good`. Rasio ketidakseimbangan 7136:1.
- **Metrik test (3267 gambar):** accuracy 0,8053; macro precision 0,1387; macro recall 0,2226; **macro F1 0,1521**; weighted F1 0,8384. Kelas-kelas kecil nyaris tak pernah terdeteksi.
- **Explainability:** rata-rata energi Grad-CAM di area air hanya 0,340 (ambang notebook 0,6); 6 dari 8 sampel fokus di luar ROI air. Model mungkin memperhatikan latar/wadah/tangan.
- **Confidence:** rata-rata 0,709 saat benar dan 0,438 saat salah - berguna sebagai penyaring kasar.
- **Dampak:** `predicted_class` bukan status kondisi air RonaAir. Jangan diterjemahkan menjadi NORMAL/WASPADA/SIAGA/DARURAT.
- **Tindakan:** (a) pakai `visual_score` sebagai sinyal utama; (b) bila ingin memakai kelas, kelompokkan lewat `labels.json` (`water_good`, `water_bad`, `other`, `algal_bloom_photo_set`) dan **hitung akurasi kelompok dari `confusion_matrix.csv`** sebelum menampilkannya; (c) tampilkan sebagai "skrining visual", dengan confidence, dan jangan otomatis mengubah status risiko.

## 4. Estimasi DO lemah dan bergantung pada waktu

- **Fakta (output notebook):**
  R² locked test = **0,4244** (MAE 3,00 mg/L, RMSE 4,08); baseline MLR R² 0,2721.
  Leave-one-source-out R² = **-2,34** (fishpond), **-0,32** (aquaponds), **-1,40** (smart aquaculture) - jauh di bawah menebak rata-rata.
  Uji lintas domain (sungai dingin) R² = -238,25.
  Feature importance: `month_sin` 0,554 + `month_cos` 0,128 ≈ **68%** - model banyak memakai musim/sumber data, bukan fisika.
- **Kesenjangan input:** model butuh `turbidity_ntu`, tetapi ESP32 RonaAir hanya punya EC/TDS. Bila kosong, pipeline mengisi median training (kolom itu praktis tidak berkontribusi). Butuh `timestamp` (jam & bulan).
- **Dampak:** rule R001-R003 (`do_est` < 2/3/5 mg/L) bisa memicu DARURAT/SIAGA/WASPADA berdasarkan estimasi yang tidak andal → risiko alarm palsu (dan sebaliknya).
- **Tindakan:** selalu tampilkan "**Estimated DO**"; sertakan `data_quality`; pertimbangkan meminta konfirmasi sensor sebelum tindakan besar (catatan R001 di notebook sudah menyebutnya).
- **Teknis:** pipeline berisi kelas kustom dari `__main__` → wajib `app.compat.load_do_pipeline` (sudah diuji). Model butuh `xgboost` di server.

## 5. Keputusan produksi = rule engine (PROVISIONAL), bukan ML

- **Fakta:** `decision_source = RULE_ENGINE_LEVEL_1`. Model ML (`DecisionTree_d6`, fitur `water_temp, ph_sensor, ec_value, tds_ppm, do_est`) hanya benchmark. Skor testnya tinggi (macro-F1 0,9928; high-risk recall 0,9941) karena **label dataset D2 direproduksi 1,0000 dari satu parameter (turbidity)** - model meniru aturan, bukan memprediksi risiko biologis.
- **Kesepakatan rule engine vs label D2:** hanya 0,7622 (keduanya mengukur hal berbeda).
- **Validasi eksternal:** tidak tersedia. Tidak ada data kolam Indonesia. Semua threshold & rekomendasi berstatus PROVISIONAL (tidak ada satu pun VALIDATED).
- **Tindakan:** jangan menampilkan probabilitas/"peluang bahaya" (sengaja tidak diekspor). Tampilkan penanda PROVISIONAL di UI. Ambang dan rekomendasi perlu ditinjau pakar budidaya sebelum dipakai sebagai keputusan nyata.

## 6. pH strip: input, ROI, dan status notebook

- **Input:** foto **pH strip**, bukan foto air. Aplikasi butuh alur pemotretan strip (dan idealnya panduan posisi/pencahayaan).
- **ROI saat inferensi:** model dilatih dengan ROI dari anotasi dataset (prioritas 1), tetapi di aplikasi anotasi tidak ada → dipakai segmentasi saturasi OpenCV lalu potong tengah (prioritas 2/3). Ini **pergeseran distribusi** yang tidak diukur notebook. Uji dengan foto strip asli Anda.
- **Rentang valid:** hanya valid pada rentang pH data latih (`model_metadata.json` → `ph_range`). Di luar itu wajib peringatan, bukan ekstrapolasi diam-diam.
- **Quality gate:** `REJECT` → `estimated_pH = null`. Aturan: brightness 25-245, kontras ≥ 8, blur (varian Laplacian) ≥ 15, ROI ≥ 80 piksel, fraksi piksel tanpa warna ≤ 0,98.
- **Metrik:** file `.ipynb` yang diunggah tidak berisi output eksekusi, jadi MAE/R² **tidak tersedia** di sini. Ambil dari `model_metadata.json` / `final_summary.json` hasil run Anda, lalu isi `models.yaml` (`metrics`).
- **Rule R040:** selisih |pH foto − pH sensor| > 1,0 → WASPADA. Ini sinyal **kualitas data** (drift sensor / foto buruk), bukan bukti bahaya.

## 7. Paritas preprocessing model CV & INT8

- **Training:** `tf.io.decode_image(channels=3)` → `tf.image.resize([224,224], antialias=True)` → `float32` (0-255) → `preprocess_input` **di dalam graph**. Jadi service harus memberi RGB float32 0-255, tanpa membagi 255.
- **Risiko:** resize Pillow/OpenCV sedikit berbeda dari TensorFlow. Uji dengan `scripts/inspect_tflite.py --image ...` dan bandingkan dengan prediksi notebook untuk gambar yang sama.
- **INT8:** `ronair_cv_classifier_int8.tflite` (1,24 MB) gagal dijalankan di Colab ("failed to create XNNPACK runtime"). Pakai varian dynamic (`ronair_cv_classifier.tflite`, latensi 5,01 ms **di Colab**, bukan di perangkat target).
- **Kalibrasi RonaCard:** heuristik konservatif (deteksi persegi netral); bila tidak terdeteksi, gambar dipakai apa adanya. Variasi kamera/pencahayaan tidak hilang sepenuhnya.

## 8. Versi library dan pemuatan model

- File `.joblib` dan `.tflite` sensitif versi. Jalankan `scripts/print_env_versions.py` di Colab dan pin `requirements.txt`. Versi yang sudah terlihat di output: fusion (Python 3.12.3, numpy 2.4.4, pandas 3.0.2, scikit-learn 1.8.0), CV (TensorFlow 2.20.0). DO & pH tidak mencetak versi.
- **Go dan Dart tidak boleh memuat `.joblib`.** Semua inferensi lewat layanan Python. (Model pH bisa diport ke Go/Dart karena berupa JSON koefisien, tetapi ekstraksi fitur OpenCV tetap di Python.)

## 9. Pemetaan `image_quality` belum didefinisikan

- Rule engine mengharapkan `image_quality` ∈ {OK, FAIL}; bila FAIL, `visual_score` diabaikan dan `data_quality` turun ke DEGRADED.
- Notebook pH menghasilkan GOOD/WARN/REJECT; notebook CV punya audit kualitas gambar terpisah. **Belum ada aturan resmi ke OK/FAIL.**
- Usulan (perlu Anda setujui): pH `REJECT` → FAIL; CV mengikuti audit kualitas (`audit_quality_for_paths`) atau aturan brightness/blur yang sama dengan pH.

## 10. Bahasa antarmuka yang harus dijaga

- "**Skrining visual** terhadap warna dan kepekatan air" - **bukan** "deteksi spesies alga", **bukan** bukti toksin/cyanobacteria.
- "**Estimated DO**", bukan "Measured DO".
- Status `INSUFFICIENT_EVIDENCE` dan `data_quality` (OK / DEGRADED / POSSIBLE_OUT_OF_DISTRIBUTION) harus terlihat.
- Penanda "PROVISIONAL" pada status risiko dan rekomendasi.
- Konteks: sistem peringatan dini + decision support, bukan pengganti laboratorium.

---

## Keputusan yang perlu Anda ambil

- [ ] **D1.** Dari CV, apa yang dipakai di produksi: hanya `visual_score`, atau juga kelompok `water_good/water_bad`? (lihat #3)
- [ ] **D2.** Konfirmasi konversi `visual_score ÷ 100` dan tinjau ambang 0,50/0,75. (#1)
- [ ] **D3.** Perlakuan `do_est` di rule engine: tetap memicu R001-R003, atau butuh konfirmasi sensor / diturunkan bobotnya? (#4)
- [ ] **D4.** Aturan `image_quality` → OK/FAIL. (#9)
- [ ] **D5.** Zona waktu untuk `hour`/`month` model DO (disarankan waktu lokal kolam, konsisten server dan perangkat).
- [ ] **D6.** Alur pemotretan pH strip di Flutter (panduan posisi, cahaya, kartu referensi).
- [ ] **D7.** Lokasi rule engine: Python (menyalin `rule_engine` dari notebook, dibaca dari `risk_rules.json`) atau Go. Disarankan Python agar satu sumber kebenaran.
- [ ] **D8.** Kolom pencatat versi model (`model_version`) di tabel hasil lewat **file migrasi SQL baru**, bukan mengedit `schema.sql`.
- [ ] **D9.** Verifikasi model final pH (`model_metadata.json`) dan isi metrik di `models.yaml`.

---

## Aturan untuk `AGENTS.md` (salin ke `AGENTS.md` di folder induk `ronaair/`)

```markdown
## Aturan ronaair_ml (wajib dipatuhi agent)
- Sumber kebenaran model: ronaair_ml/models.yaml dan ronaair_ml/models/*/MODEL_SPEC.md. Baca sebelum mengubah apa pun.
- JANGAN mengarang metrik/angka. Ambil dari model_metadata.json; bila tidak ada, tulis "tidak tersedia".
- Urutan fitur diambil dari feature_schema.json / models.yaml. JANGAN mengubah urutan atau rumus fitur.
- Pipeline DO WAJIB dimuat lewat app.compat.load_do_pipeline (kelas kustom dari notebook).
- visual_score dari modul CV berskala 0-100; bagi 100 sebelum masuk risk_fusion (skala 0-1).
- Keputusan risiko = rule engine (decision_source RULE_ENGINE_LEVEL_1). JANGAN menampilkan probabilitas ML sebagai "peluang bahaya".
- Tampilkan DO sebagai "Estimated DO". JANGAN mengklaim deteksi spesies alga atau toksin.
- Go/Dart TIDAK boleh memuat .joblib/.tflite; hanya layanan Python ronaair_ml yang melakukan inferensi.
- JANGAN mengedit ronaair_backend/database/schema.sql; buat file migrasi baru dan minta backup DB dulu.
- Minta konfirmasi sebelum: pip install, perintah yang menghapus data/berkas, atau perubahan skema database.
- Kerjakan satu model per putaran; uji ujung-ke-ujung dengan samples/ sebelum lanjut.
```
