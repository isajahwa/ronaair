# Model Card — RonaAir DO Soft Sensor (XGBoost)

## Ringkasan
Model regresi untuk mengestimasi Dissolved Oxygen (mg/L) dari sensor
suhu, pH, dan turbidity air kolam budidaya air tawar tropis, plus fitur
siklus waktu (jam, bulan).

## Data
- **Dipakai untuk training** (55,472 baris setelah cleaning):
  fishpond_dataset_multiclass_2153.csv, Aquaponds_Dataset.csv,
  Smart Aqualcuture Dashboard - June Data.csv.
- **Dikecualikan dari training**: Data_Model_IoTMLCQ_2024.csv (hanya
  6 kombinasi sensor unik -- risiko leakage tinggi, informasi
  baru nyaris nol).
- **Held-out cross-domain test**: QC1_complete_Soapstone_Hydroshare.csv
  (stasiun sungai air dingin, domain berbeda dari kolam tropis).

## Performa
- Random split (locked test set): R²=0.4244, MAE=3.0011 mg/L, RMSE=4.0794 mg/L
- Baseline mean: R²=-0.0002
- Baseline MLR: R²=0.2721
- Leave-one-source-out (generalisasi lintas kolam/sensor, lebih ketat): lihat
  `model_metadata.json` -> `metrics.leave_one_source_out`.

## Batasan yang diketahui
1. Fitur `month_sin`/`month_cos` berpotensi ikut membawa sidik jari sumber
   dataset karena dua dari tiga dataset training hanya mencakup sebagian
   kecil kalender (lihat Cell 10-12 & 22-25).
2. Model hanya melihat temp/pH/turbidity -- tidak bisa mendeteksi lonjakan
   alga/fotosintesis secara langsung, itulah motivasi komponen computer
   vision RonaAir.
3. Performa di luar domain kolam tropis (air dingin, mis. sungai) jauh lebih
   buruk -- lihat evaluasi Soapstone di Cell 22-25.

## Deployment
Lihat diskusi ESP32 vs Android di Cell 22-25. Model penuh (XGBoost) paling
cocok dijalankan di Android/cloud; ESP32 sebaiknya hanya menjalankan
pembacaan sensor + rumus saturasi DO sebagai fallback ringan.
