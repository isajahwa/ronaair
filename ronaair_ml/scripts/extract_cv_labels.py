#!/usr/bin/env python3
"""
extract_cv_labels.py - buat labels.json untuk model CV dari model_metadata.json asli.

Model `ronair_cv_classifier.tflite` mengeluarkan 31 skor softmax. Urutan kelasnya
disimpan notebook di model_metadata.json -> supervised_evaluation.classes.
Urutan itulah satu-satunya kebenaran untuk memetakan indeks -> nama kelas.

Skrip ini juga memberi setiap kelas sebuah GRUP semantik:
    water_good | water_bad | other | algal_bloom_photo_set | unknown_folder
karena 28 dari 31 kelas hanyalah folder foto "algal bloom" per lokasi (Swedia),
bukan kelas kondisi air RonaAir.

Pemakaian (dari folder ronaair_ml):
    python scripts/extract_cv_labels.py
    python scripts/extract_cv_labels.py --metadata path/ke/model_metadata.json --out path/labels.json
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DIR = ROOT / "models" / "cv_water_visual" / "v1"


def group_of(name: str) -> str:
    if name == "water_good":
        return "water_good"
    if name == "water_bad":
        return "water_bad"
    if name == "other":
        return "other"
    if name.startswith(("Algbl", "algal_blooms")):
        return "algal_bloom_photo_set"
    return "unknown_folder"          # mis. 'Kommunens_bilder' - isi folder tidak terdokumentasi


def build(classes: list[str]) -> dict:
    return {
        "note": "Indeks = posisi keluaran softmax model. Nama berasal dari label FOLDER dataset (bukan kelas RonaAir). "
                "Sebagian nama memuat karakter rusak akibat encoding nama file zip; itu tidak memengaruhi urutan.",
        "n_classes": len(classes),
        "classes": [{"index": i, "name": n, "group": group_of(n)} for i, n in enumerate(classes)],
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--metadata", default=str(DEFAULT_DIR / "model_metadata.json"))
    ap.add_argument("--out", default=str(DEFAULT_DIR / "labels.json"))
    args = ap.parse_args()

    meta_p = Path(args.metadata)
    if not meta_p.exists():
        print(f"[GAGAL] {meta_p} tidak ada. Salin model_metadata.json hasil training CV dulu.", file=sys.stderr)
        return 1
    meta = json.loads(meta_p.read_text(encoding="utf-8"))
    classes = (meta.get("supervised_evaluation") or {}).get("classes")
    if not isinstance(classes, list) or not classes:
        print("[GAGAL] supervised_evaluation.classes tidak ditemukan/bukan list di metadata.", file=sys.stderr)
        return 1

    out = build([str(c) for c in classes])
    Path(args.out).write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding="utf-8")
    groups: dict[str, int] = {}
    for c in out["classes"]:
        groups[c["group"]] = groups.get(c["group"], 0) + 1
    print(f"Tersimpan: {args.out}  ({out['n_classes']} kelas)  grup: {groups}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
