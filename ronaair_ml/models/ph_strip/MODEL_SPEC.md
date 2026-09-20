# MODEL_SPEC - `ph_strip` (estimasi pH dari foto pH strip)

| | |
|---|---|
| Sumber | `RonaAir_pH_Strip_AI_Colab.ipynb` (`MODEL_VERSION = "ronair-ph-1.0.0"`) |
| Jenis | Regresi klasik pada fitur warna ROI (bukan deep learning) |
| Model final | **`PolynomialRidge2` pada feature set `COMBINED_ALL`** - menurut catatan notebook fusion. **Belum terverifikasi**: notebook yang diunggah tidak punya output eksekusi. Konfirmasi dari `model_metadata.json` (`final_model`, `final_feature_set`). |
| Endpoint rencana | `POST /predict/ph-strip` (multipart, field `image`) |
| Peran | Menghasilkan `ph_visual_est` (kanal pH kedua; dibandingkan dengan `ph_sensor` oleh rule R040) |
| Status | Aktif, **belum diverifikasi** |

## 1. Artefak (di `v1/`)

| File | Status |
|---|---|
| `model_coefficients.json` | WAJIB (model) |
| `feature_schema.json`, `preprocessing_config.json`, `model_metadata.json` | WAJIB |
| `model_card.md`, `final_summary.json` | PENDUKUNG |
| `final_model.joblib` | CADANGAN (butuh scikit-learn versi sama) |

Model dijalankan **native dari JSON** - tidak butuh scikit-learn saat inferensi.

## 2. Input

Foto **pH strip** (jpg/jpeg/png/bmp/webp). **Bukan** foto air kolam.

### 2.1 Alur pemrosesan

```
foto ─► decode BGR (cv2.imread) ─► ROI ─► quality gate ─► 24 fitur warna ─► model ─► estimated_pH
```

### 2.2 ROI (saat inferensi tidak ada anotasi dataset)

1. Segmentasi saturasi OpenCV: mask `S > max(60, persentil-90 S)` dan `40 < V < 250`; open 5×5, close 9×9; ambil kontur terbesar (luas > 0,0008 × H × W); potong 20% ke arah pusat pada tiap sisi (lebar/tinggi jadi 60%). Metode: `opencv_saturation_segmentation`.
2. Jika tidak ada kontur: potong tengah `W/6 × H/12`. Metode: `center_crop_fallback`.

> Model dilatih dengan ROI dari anotasi dataset; ROI segmentasi di aplikasi adalah pergeseran distribusi yang tidak diukur di notebook. Uji dengan foto strip asli Anda.

Kode acuan: notebook, sel `crop_by_position_rect / roi_fallback_segmentation / get_roi` dan `check_image_quality`.

### 2.3 Quality gate (`preprocessing_config.json` → `quality_rules`)

| Aturan | Nilai | Kode alasan |
|---|---|---|
| Kecerahan rata-rata (abu-abu) minimum | 25.0 | `image_too_dark` |
| Kecerahan maksimum | 245.0 | `image_overexposed` |
| Kontras (std abu-abu) minimum | 8.0 | `low_contrast` |
| Blur (varian Laplacian) minimum | 15.0 | `blurry` |
| Piksel ROI minimum | 80 | `roi_too_small` |
| ROI kosong | - | `roi_empty` |
| Fraksi piksel S < 12 maksimum | 0.98 | `roi_not_colourful` |

`REJECT` bila ada salah satu: `roi_empty, roi_too_small, roi_not_colourful, image_too_dark, image_overexposed`. `low_contrast` / `blurry` saja → `WARN`. Selain itu `GOOD`.

## 3. Fitur (24, urutan resmi ada di `feature_schema.json`)

Blok `R, G, B, rn, gn, bn, H, S, V, L, a, blab`, masing-masing `mean` lalu `std` pada piksel ROI:

`R_mean, R_std, G_mean, G_std, B_mean, B_std, rn_mean, rn_std, gn_mean, gn_std, bn_mean, bn_std, H_mean, H_std, S_mean, S_std, V_mean, V_std, L_mean, L_std, a_mean, a_std, blab_mean, blab_std`

Definisi:

- `R,G,B` dari gambar BGR OpenCV (0-255); `rn = R/(R+G+B+1e-6)` (idem `gn`, `bn`).
- `H,S,V` = `cv2.COLOR_BGR2HSV` 8-bit (H 0-179, S/V 0-255).
- `L,a,blab` = `cv2.COLOR_BGR2LAB` 8-bit (L 0-255; a dan b digeser +128).
- Fitur dihitung pada ROI **resolusi asli**, tanpa resize.
- `COMBINED_ALL` tidak memakai fitur normalisasi putih (`n_*`), jadi tidak butuh patch referensi.

Kode acuan: sel `color_features` (`COLOR_BLOCKS`, `RAW_FEATURES`).

## 4. Model native (`model_coefficients.json`)

```
x  = vektor 24 fitur sesuai feature_order
z  = (x − scaler.mean) / scaler.scale
t  = ekspansi polinomial derajat 2 tanpa bias:  t_j = Π_i z_i ^ powers[j][i]   (24 linear + 300 kuadratik = 324 suku)
pH = dot(coefficients, t) + intercept
```

Implementasi acuan (identik dengan notebook):

```python
X = (X - np.array(spec["scaler"]["mean"])) / np.array(spec["scaler"]["scale"])
P = np.array(spec["polynomial"]["powers"], dtype=float)
X = np.stack([np.prod(X ** P[j], axis=1) for j in range(P.shape[0])], axis=1)
ph = X @ np.array(spec["coefficients"]) + spec["intercept"]
```

Notebook memverifikasi selisih maksimum vs sklearn < 1e-6 sebelum mengekspor.
Jika `final_model` di metadata ternyata **bukan** LinearRegression/Ridge/PolynomialRidge2 (mis. `KerasMLP_16_8_1`), jalur deploy-nya `final_model.tflite` + `scaler.joblib` dan spesifikasi ini harus diperbarui.

## 5. Output

```json
{
  "estimated_pH": 0.0,
  "image_quality_status": "GOOD",
  "quality_reasons": "",
  "validated_pH_range": [0.0, 0.0],
  "warnings": [],
  "roi_method": "opencv_saturation_segmentation",
  "roi_bbox": [0, 0, 0, 0],
  "reference_source": "none",
  "model": "PolynomialRidge2",
  "model_version": "ronair-ph-1.0.0",
  "brightness": 0.0,
  "blur_score": 0.0
}
```

- `REJECT` → `estimated_pH: null`, tambahkan `message` "Image rejected by the quality gate; no pH is reported."
- `validated_pH_range` diambil dari `model_metadata.json` → `ph_range.train`.
- Peringatan rentang: bila `estimated_pH < lo − 0.5` atau `> hi + 0.5` → "di luar rentang pH tervalidasi; estimasi diekstrapolasi". Jangan dipotong diam-diam.
- Nilai non-finite pada fitur → kesalahan input yang jelas, bukan prediksi.
- **Tidak ada** probabilitas/kepercayaan: hanya estimasi titik.

## 6. Metrik

Tidak tersedia pada file `.ipynb` yang diunggah (tanpa output eksekusi). Ambil dari `model_metadata.json` → `test_metrics` (`MAE, RMSE, R2, within_0.25, within_0.5, within_1.0`) dan `selection_cv_MAE`, `validation_MAE`, lalu isi `models.yaml`. **Jangan mengisi dengan angka perkiraan.**

Prosedur evaluasi di notebook: seleksi model dengan CV 5-fold berbasis grup pada split latih (menghindari kebocoran foto sampel yang sama), test set dievaluasi sekali. Ada satu subset "coloured-matrix" yang disisihkan sebagai uji lintas domain.

## 7. Uji penerimaan

1. `verify_artifacts.py --load --model ph_strip`: 24 fitur, `feature_order` JSON = `feature_schema.json`, `final_model` = `PolynomialRidge2`.
2. Foto strip gelap/blur/tertutup harus menghasilkan `REJECT`/`WARN` yang sesuai, bukan pH.
3. **Parity:** di Colab hasilkan berkas emas (mode aplikasi, tanpa anotasi), simpan sebagai `samples/ph_golden_samples.json`, lalu bandingkan dengan service (toleransi 1e-3 pH):

```python
import json, os
gold = []
for p in sample_image_paths[:10]:                       # path foto strip pilihan Anda
    r = predict_ph_from_image(p, record=None, verbose=False)   # record=None = tanpa anotasi (seperti di aplikasi)
    gold.append({"image": os.path.basename(p), **r})
json.dump(gold, open("ph_golden_samples.json", "w"), indent=2, default=str)
```

## 8. Catatan implementasi untuk agent

- Ekstraksi fitur harus dilakukan di Python (OpenCV). Hanya langkah model yang bisa diport ke bahasa lain.
- `PhPredictor.kt` (Android) tidak dipakai; boleh dibaca sebagai referensi rumus.
- Simpan foto strip apa adanya untuk audit; jangan dikompres ulang sebelum inferensi (mengubah warna).
