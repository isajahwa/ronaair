#!/usr/bin/env python3
"""
inspect_tflite.py - periksa model TFLite RonaAir dan uji satu gambar.

Tujuan utama: MEMASTIKAN kontrak input (shape, dtype, rentang nilai) sebelum service dibuat.
Di notebook, preprocessing dilakukan begini (fungsi load_image_tensor + preprocess_input di dalam graph):
    decode RGB -> resize 224x224 (bilinear, antialias) -> float32 rentang 0..255
Skrip ini meniru itu memakai Pillow. Karena Pillow/OpenCV/TensorFlow menghitung resize
sedikit berbeda, bandingkan hasilnya dengan prediksi di notebook untuk gambar yang sama.

Pemakaian (dari folder ronaair_ml):
    python scripts/inspect_tflite.py
    python scripts/inspect_tflite.py --model models/cv_water_visual/v1/ronair_cv_classifier_int8.tflite
    python scripts/inspect_tflite.py --image samples/kolam_01.jpg --labels models/cv_water_visual/v1/labels.json

Butuh salah satu: `ai-edge-litert` (disarankan) ATAU `tensorflow`. Untuk --image juga butuh pillow & numpy.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MODEL = ROOT / "models" / "cv_water_visual" / "v1" / "ronair_cv_classifier.tflite"


def make_interpreter(path: Path):
    try:
        from ai_edge_litert.interpreter import Interpreter  # type: ignore

        return Interpreter(model_path=str(path))
    except ImportError:
        pass
    try:
        import tensorflow as tf  # type: ignore

        return tf.lite.Interpreter(model_path=str(path))
    except ImportError:
        sys.exit("Butuh 'ai-edge-litert' atau 'tensorflow': pip install ai-edge-litert")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--model", default=str(DEFAULT_MODEL))
    ap.add_argument("--image", help="gambar untuk diuji (opsional)")
    ap.add_argument("--labels", help="labels.json (dari extract_cv_labels.py) untuk menamai kelas")
    ap.add_argument("--top", type=int, default=5)
    args = ap.parse_args()

    import numpy as np

    model_path = Path(args.model)
    if not model_path.exists():
        print(f"[GAGAL] model tidak ada: {model_path}", file=sys.stderr)
        return 1

    it = make_interpreter(model_path)
    it.allocate_tensors()
    inp, out = it.get_input_details()[0], it.get_output_details()[0]

    print(f"Model : {model_path.name}  ({model_path.stat().st_size / 1e6:.2f} MB)")
    print(f"Input : shape={list(inp['shape'])} dtype={np.dtype(inp['dtype']).name} quantization={inp.get('quantization')}")
    print(f"Output: shape={list(out['shape'])} dtype={np.dtype(out['dtype']).name} quantization={out.get('quantization')}")

    if np.dtype(inp["dtype"]) != np.float32:
        print("[PERHATIAN] input BUKAN float32. Model ini butuh kuantisasi input manual "
              "(x_int = x_float/scale + zero_point). Model dinamis/float notebook seharusnya float32.")

    # --- uji dummy + latensi
    dummy = np.random.default_rng(0).uniform(0, 255, size=inp["shape"]).astype(inp["dtype"])
    it.set_tensor(inp["index"], dummy)
    it.invoke()
    t0 = time.perf_counter()
    n = 20
    for _ in range(n):
        it.set_tensor(inp["index"], dummy)
        it.invoke()
    print(f"Latensi (dummy, {n} run, mesin ini): {(time.perf_counter() - t0) / n * 1000:.2f} ms/gambar")

    # --- uji satu gambar
    if args.image:
        from PIL import Image

        img = Image.open(args.image).convert("RGB").resize((224, 224), Image.BILINEAR)
        x = np.asarray(img, dtype=np.float32)[None, ...]           # 0..255, RGB
        it.set_tensor(inp["index"], x.astype(inp["dtype"]))
        it.invoke()
        probs = it.get_tensor(out["index"])[0].astype(np.float64)
        print(f"\nGambar: {args.image}  (jumlah softmax = {probs.sum():.3f}; harapan ~1.0)")

        names = None
        if args.labels and Path(args.labels).exists():
            names = [c["name"] for c in json.loads(Path(args.labels).read_text(encoding="utf-8"))["classes"]]
        for i in np.argsort(probs)[::-1][: args.top]:
            label = names[i] if names and i < len(names) else f"kelas_{i}"
            print(f"  {i:>2}  {probs[i]:.4f}  {label}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
