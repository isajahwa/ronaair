# MODEL_SPEC - `cv_water_visual` (skrining visual warna & kepekatan air)

| | |
|---|---|
| Sumber | `Copy_of_RonaAir_CV_RGB_DeepLearning_FINAL.ipynb` |
| Komponen | (a) classifier MobileNetV3-Small → TFLite; (b) deskriptor warna OpenCV + **Visual Score 0-100** |
| Versi aktif | `v1` (folder `models/cv_water_visual/v1/`) |
| Endpoint rencana | `POST /predict/water-visual` (multipart, field `image`) |
| Peran | Menghasilkan `visual_score` dan `visual_condition` untuk `risk_fusion` |
| Status | Aktif, **terbatas**: kelas terlatih = label folder mentah (31 kelas) |

**Framing yang benar:** "AI melakukan skrining visual terhadap karakteristik warna dan kepekatan air."
**Salah:** "AI mendeteksi spesies alga / membuktikan toksin." Foto air bukan pengukuran kimia.

## 1. Artefak (di `v1/`)

| File | Status |
|---|---|
| `ronair_cv_classifier.tflite` (1,13 MB, dynamic) | WAJIB |
| `model_metadata.json` | WAJIB (daftar kelas resmi di `supervised_evaluation.classes`) |
| `android_deployment_runtime.json`, `classification_report.csv`, `confusion_matrix.csv`, `label_mapping_table.csv` | PENDUKUNG |
| `labels.json` | Dibuat dengan `scripts/extract_cv_labels.py` (sementara: `labels.provisional.json`) |
| `ronair_cv_classifier_int8.tflite` | OPSIONAL - **jangan dipakai** (gagal dijalankan di Colab) |

## 2. Bagian A - classifier TFLite

### 2.1 Tensor masuk

- Bentuk `[1, 224, 224, 3]`, `float32`, RGB, nilai **0-255** (tanpa dibagi 255).
- `preprocess_input` MobileNetV3 sudah **di dalam graph**.
- Pra-pemrosesan training: `tf.io.decode_image(channels=3)` → `tf.image.resize([224,224], antialias=True)` → `float32`.
- Verifikasi kontrak nyata dengan `python scripts/inspect_tflite.py` (mencetak shape/dtype/kuantisasi).

### 2.2 Tensor keluar

31 nilai softmax. Urutan = urutan `supervised_evaluation.classes` (terurut alfabet Python). Ringkasan:

| Indeks | Nama | Grup |
|---|---|---|
| 0-25 | `Algbl_*` / `Algblomning_*` (folder foto per lokasi, Swedia) | `algal_bloom_photo_set` |
| 26 | `Kommunens_bilder` | `unknown_folder` |
| 27 | `algal_blooms_sweden_2023` | `algal_bloom_photo_set` |
| 28 | `other` | `other` |
| 29 | `water_bad` | `water_bad` |
| 30 | `water_good` | `water_good` |

Sebagian nama memuat karakter rusak (encoding nama file ZIP); itu tidak memengaruhi urutan indeks. Pakai `labels.json`, jangan menyalin nama secara manual.

### 2.3 Metrik (test, n = 3.267)

| Metrik | Nilai |
|---|---|
| Accuracy | 0,8053 |
| Macro precision / recall / F1 | 0,1387 / 0,2226 / **0,1521** |
| Weighted F1 | 0,8384 |
| Error rate | 0,1947 (2.631 benar / 636 salah) |
| Confidence rata-rata (benar / salah) | 0,709 / 0,438 |
| Silhouette fitur warna vs kelas | -0,3381 (negatif) |
| Silhouette embedding MobileNetV3 vs kelas | -0,0869 (negatif) |
| Kebocoran data (grup & SHA-256 lintas split) | OK (0 kebocoran) |

Data: 22.379 gambar valid (dataset_1 22.231; dataset_2 148); 2.820 duplikat SHA-256; split berbasis grup train/val/test = 15.809 / 3.303 / 3.267; rasio ketidakseimbangan 7136:1 (class weight, tanpa oversampling). Pelatihan 2 tahap: head 5 epoch, fine-tune 10 epoch (early stopping).

**Cara membaca:** akurasi 80,5% didominasi tiga kelas besar (`water_good` ≈ 14.273, `water_bad` ≈ 4.515, `other` ≈ 3.443 gambar). Kelas lokasi-algal-bloom kecil nyaris tak terdeteksi (macro F1 0,15). Empat status RonaAir (NORMAL/WASPADA/SIAGA/DARURAT) **tidak dilatih dari foto**.

Grad-CAM: energi rata-rata di ROI air 0,340 (ambang 0,6); 6 dari 8 sampel fokus di luar ROI air → model mungkin memperhatikan latar/wadah/tangan.

Latensi TFLite dynamic 5,01 ms/gambar - diukur di Colab, **bukan** perangkat target.

### 2.4 Rekomendasi pemakaian

- Jangan menerjemahkan `predicted_class` menjadi status risiko.
- Bila ingin menampilkan kelas, kelompokkan (lihat tabel 2.2) dan **hitung akurasi kelompok dari `confusion_matrix.csv`** dulu.
- Tampilkan `confidence`; pertimbangkan menyembunyikan hasil ber-confidence rendah (kesalahan rata-rata 0,438).

## 3. Bagian B - deskriptor warna & Visual Score (Python/OpenCV)

**`visual_score` dihitung di sini, bukan oleh TFLite.** Port dari notebook (sel definisi pertama): `detect_ronacard`, `calibrate_with_ronacard`, `extract_water_roi`, `roi_pixels`, `extract_visual_features`, `compute_visual_score`.

### 3.1 Langkah

1. `cv2.imread` (BGR).
2. **RonaCard** (heuristik konservatif): mask `S < 35 & 70 < V < 245`, close/open 5×5; kandidat kontur dengan lebar ≥ 8% W, tinggi ≥ 5% H, rasio lebar/tinggi 0,5-4,0; skor `luas_frac × (1 − |rasio − 1.8|/3)`; terdeteksi bila skor ≥ 0,002.
3. **Kalibrasi**: bila terdeteksi, skala kanal = `mean(median_patch) / max(median_patch, 1)`; bila tidak, gambar dipakai apa adanya.
4. **ROI air**: mask persegi panjang tengah (buang 8% atas & bawah, 5% kiri & kanan); bbox RonaCard (+8 px) dikeluarkan.
5. Fitur warna hanya dari piksel ROI: RGB (rata-rata, median, std, persentil), RGB ternormalisasi (`norm_r/g/b`), HSV, CIELAB (`L*`, `a*`, `b*`, chroma, hue), rasio piksel hijau/cokelat, tekstur (Canny, Sobel), histogram 8-bin.

### 3.2 Visual Score (0-100, deterministik)

```
green_chroma = clip((norm_g − 1/3) / 0.12, 0, 1)
lab_green    = clip((−a*) / 25, 0, 1)
saturation   = clip(hsv_s_norm_mean, 0, 1)
density      = clip((60 − L*) / 40, 0, 1)
VS = 100 × (0,35·green_chroma + 0,25·lab_green + 0,20·saturation + 0,20·density)
```

Rata-rata VS pada dataset = 27,40 (min 0,00; maks 93,95). VS adalah deskriptor warna, **bukan** probabilitas, akurasi, atau ukuran kimia.

> Untuk `risk_fusion`, gunakan `visual_score / 100` (skala 0-1). Lihat `../../INTEGRATION_NOTES.md` #1.

## 4. Kontrak output layanan (usulan bentuk)

```json
{
  "predicted_class": "water_good",
  "predicted_group": "water_good",
  "confidence": 0.0,
  "visual_score": 0.0,
  "visual_score_unit": 0.0,
  "color": {
    "mean_rgb": [0, 0, 0],
    "normalized_rgb": [0.0, 0.0, 0.0],
    "hsv": {"h_deg": 0.0, "s": 0.0, "v": 0.0},
    "cielab": {"L": 0.0, "a": 0.0, "b": 0.0}
  },
  "ronacard": {"detected": false, "calibrated": false},
  "image_quality": "OK",
  "warnings": [],
  "model_version": "v1"
}
```

- `visual_score` 0-100; `visual_score_unit` = `visual_score / 100` (untuk fusion).
- `image_quality` ∈ {OK, FAIL}; aturan pemetaannya perlu diputuskan (INTEGRATION_NOTES D4).

## 5. Uji penerimaan

1. `python scripts/inspect_tflite.py` mencetak input `[1,224,224,3] float32` dan output `[1,31]`.
2. `python scripts/extract_cv_labels.py` menghasilkan `labels.json` dengan 31 kelas.
3. Untuk 10 gambar uji, prediksi & Visual Score service cocok dengan notebook (toleransi softmax ≈ 1e-2 karena beda resize; Visual Score ≈ 0,1). Berkas emas di Colab:

```python
import json, os
gold = []
for p in sample_image_paths[:10]:
    feat = extract_visual_features(p)
    x = load_image_tensor(p)[None, ...]                      # float32 0..255, 224x224
    probs = TRAINED_KERAS_MODEL.predict(x, verbose=0)[0]
    gold.append({"image": os.path.basename(p),
                 "visual_score": feat["visual_score"],
                 "top_index": int(probs.argmax()), "top_prob": float(probs.max())})
json.dump(gold, open("cv_golden_samples.json", "w"), indent=2)
```

4. Foto tanpa RonaCard tetap diproses (`ronacard.detected=false`), tanpa error.

## 6. Batasan ilmiah (dari notebook)

- Foto air bukan pengukuran kimia langsung; warna ≠ bukti cyanobacteria/cyanotoxin/klorofil-a/DO/kekeruhan.
- Model tidak mengidentifikasi spesies alga maupun toksin.
- Heuristik RonaCard tidak menghilangkan seluruh variasi kamera (white balance otomatis, HDR, eksposur, pantulan permukaan).
- Nama folder tidak dianggap kebenaran dasar kecuali divalidasi pengguna; diperlukan validasi eksternal sebelum klaim performa lapangan.
- Output CV hanyalah **satu input** Decision Fusion, bukan keputusan akhir.
