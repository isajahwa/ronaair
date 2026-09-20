#!/usr/bin/env python3
"""
print_env_versions.py - catat versi library di lingkungan TRAINING (Colab).

KENAPA PENTING
--------------
File .joblib (scikit-learn / XGBoost) dan model TFLite sensitif terhadap versi library.
Layanan ronaair_ml HARUS memakai versi yang sama (atau uji parity ulang), jika tidak
prediksi bisa berubah diam-diam atau model gagal dimuat.

CARA PAKAI
----------
1. Buka notebook training yang sama di Colab (runtime yang sama dengan saat training).
2. Upload file ini ke Colab (panel Files -> Upload), lalu jalankan di sebuah cell:
       %run print_env_versions.py
   (atau tempel isi file ini ke cell lalu jalankan)
3. Unduh `env_versions.json`, taruh di folder ronaair_ml/, lalu isi pin versi di requirements.txt.

Catatan: versi yang tercatat di output notebook yang sudah ada (bukan dari Anda menjalankan ini):
  - Fusion notebook : Python 3.12.3, numpy 2.4.4, pandas 3.0.2, scikit-learn 1.8.0 (xgboost tidak terpasang)
  - CV notebook     : TensorFlow 2.20.0, OpenCV 5.0.0 (Colab)
  - DO & pH notebook: TIDAK mencetak versi library -> jalankan skrip ini.
"""
import importlib
import json
import platform
import sys

PACKAGES = [
    "numpy", "pandas", "scipy", "sklearn", "xgboost", "joblib",
    "tensorflow", "keras", "cv2", "PIL", "yaml", "ai_edge_litert",
]


def version_of(name: str):
    try:
        mod = importlib.import_module(name)
        return getattr(mod, "__version__", "terpasang (versi tidak diketahui)")
    except Exception:  # noqa: BLE001
        return None


def main() -> None:
    info = {
        "python": sys.version.split()[0],
        "platform": platform.platform(),
        "packages": {p: version_of(p) for p in PACKAGES},
    }
    info["packages"] = {k: v for k, v in info["packages"].items() if v is not None}
    text = json.dumps(info, indent=2, ensure_ascii=False)
    print(text)
    with open("env_versions.json", "w", encoding="utf-8") as f:
        f.write(text)
    print("\nTersimpan: env_versions.json")


if __name__ == "__main__":
    main()
