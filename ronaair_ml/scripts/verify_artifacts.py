#!/usr/bin/env python3
"""
verify_artifacts.py - cek bahwa file hasil training sudah disalin ke ronaair_ml/models/.

Membaca models.yaml, lalu untuk tiap model memeriksa folder `artifact_dir`:
  - artefak `required`            -> HARUS ada (gagal bila hilang)
  - artefak `recommended`         -> sebaiknya ada (peringatan)
  - `optional/fallback/benchmark_optional` -> hanya info

Pemakaian (dari folder ronaair_ml):
    python scripts/verify_artifacts.py                 # laporan
    python scripts/verify_artifacts.py --load          # + coba muat/uji model (butuh library terpasang)
    python scripts/verify_artifacts.py --model ph_strip
    python scripts/verify_artifacts.py --checksums     # tulis CHECKSUMS.txt (SHA-256)

Exit code 0 = semua artefak wajib ada; 1 = ada yang hilang/rusak.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.exit("PyYAML belum terpasang: pip install pyyaml")

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

OK, WARN, FAIL = "[ OK ]", "[WARN]", "[FAIL]"


def human(n: int) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1024
    return f"{n} B"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def check_json(path: Path) -> str | None:
    try:
        json.loads(path.read_text(encoding="utf-8"))
        return None
    except Exception as e:  # noqa: BLE001
        return f"JSON rusak: {e}"


# --------------------------------------------------------------------------- smoke tests
def smoke_do(art_dir: Path, spec: dict) -> list[tuple[str, str]]:
    res = []
    try:
        from app.compat import build_do_input_row, load_do_pipeline

        model = load_do_pipeline(art_dir / "ronaair_do_xgboost_final.joblib")
        row = build_do_input_row(28.0, 7.2, None, "2026-01-01 14:00:00")
        pred = float(model.predict(row)[0])
        res.append((OK, f"model dimuat; contoh prediksi DO = {pred:.3f} mg/L (input 28C, pH 7.2, tanpa turbidity)"))
        if not (0.0 <= pred <= 25.0):
            res.append((WARN, "prediksi di luar rentang plausibel 0-25 mg/L"))
    except Exception as e:  # noqa: BLE001
        res.append((FAIL, f"gagal memuat/menjalankan model DO: {type(e).__name__}: {e}"))
    return res


def smoke_ph(art_dir: Path, spec: dict) -> list[tuple[str, str]]:
    res = []
    try:
        import numpy as np

        coef = json.loads((art_dir / "model_coefficients.json").read_text(encoding="utf-8"))
        schema = json.loads((art_dir / "feature_schema.json").read_text(encoding="utf-8"))
        meta_p = art_dir / "model_metadata.json"
        n = len(schema["feature_order"])
        res.append((OK if n == 24 else WARN, f"jumlah fitur = {n} (harapan 24 untuk COMBINED_ALL)"))
        if coef.get("feature_order") != schema["feature_order"]:
            res.append((FAIL, "feature_order di model_coefficients.json BERBEDA dari feature_schema.json"))
        # prediksi native dari JSON (rumus yang sama dengan notebook)
        x = np.array([schema["feature_stats"][f]["mean"] for f in schema["feature_order"]], dtype=float)[None, :]
        if "scaler" in coef:
            x = (x - np.array(coef["scaler"]["mean"])) / np.array(coef["scaler"]["scale"])
        if "polynomial" in coef:
            p = np.array(coef["polynomial"]["powers"], dtype=float)
            x = np.stack([np.prod(x ** p[j], axis=1) for j in range(p.shape[0])], axis=1)
        ph = float((x @ np.array(coef["coefficients"]) + coef["intercept"])[0])
        res.append((OK, f"prediksi native dari JSON pada 'fitur rata-rata' = pH {ph:.2f} ({coef.get('model_type')}, {len(coef['coefficients'])} koefisien)"))
        if meta_p.exists():
            meta = json.loads(meta_p.read_text(encoding="utf-8"))
            exp = spec.get("expected_final_model")
            got = meta.get("final_model")
            res.append((OK if got == exp else WARN, f"final_model di metadata = {got} (harapan: {exp})"))
            res.append((OK, f"rentang pH valid (train) = {meta.get('ph_range', {}).get('train')}"))
    except Exception as e:  # noqa: BLE001
        res.append((FAIL, f"gagal uji pH: {type(e).__name__}: {e}"))
    return res


def smoke_cv(art_dir: Path, spec: dict) -> list[tuple[str, str]]:
    res = []
    model = art_dir / "ronair_cv_classifier.tflite"
    interp = None
    try:
        try:
            from ai_edge_litert.interpreter import Interpreter  # type: ignore

            interp = Interpreter(model_path=str(model))
        except ImportError:
            import tensorflow as tf  # type: ignore

            interp = tf.lite.Interpreter(model_path=str(model))
        interp.allocate_tensors()
        i = interp.get_input_details()[0]
        o = interp.get_output_details()[0]
        res.append((OK, f"TFLite dimuat; input {list(i['shape'])} {i['dtype'].__name__}; output {list(o['shape'])}"))
        if list(i["shape"]) != [1, 224, 224, 3]:
            res.append((WARN, "bentuk input tidak sama dengan [1,224,224,3]"))
    except ImportError:
        res.append((WARN, "ai-edge-litert / tensorflow belum terpasang - uji TFLite dilewati"))
    except Exception as e:  # noqa: BLE001
        res.append((FAIL, f"gagal memuat TFLite: {type(e).__name__}: {e}"))

    meta_p = art_dir / "model_metadata.json"
    if meta_p.exists():
        meta = json.loads(meta_p.read_text(encoding="utf-8"))
        classes = (meta.get("supervised_evaluation") or {}).get("classes")
        if isinstance(classes, list):
            res.append((OK if len(classes) == 31 else WARN, f"jumlah kelas di metadata = {len(classes)} (harapan 31)"))
        else:
            res.append((WARN, "supervised_evaluation.classes tidak ditemukan di model_metadata.json"))
    return res


def smoke_fusion(art_dir: Path, spec: dict) -> list[tuple[str, str]]:
    res = []
    try:
        rules = json.loads((art_dir / "risk_rules.json").read_text(encoding="utf-8"))
        ids = [r["rule_id"] for r in rules["rules"]]
        expected = list(spec["rules"]["table"].keys())
        missing = sorted(set(expected) - set(ids))
        extra = sorted(set(ids) - set(expected))
        res.append((OK if not missing else WARN, f"{len(ids)} rule dimuat; hilang dibanding models.yaml: {missing or '-'}; tambahan: {extra or '-'}"))
        for r in rules["rules"]:
            exp = spec["rules"]["table"].get(r["rule_id"])
            if exp and (float(exp["value"]) != float(r["threshold"]) or exp["op"] != r["operator"]):
                res.append((WARN, f"{r['rule_id']}: {r['operator']} {r['threshold']} di file != {exp['op']} {exp['value']} di models.yaml"))
    except Exception as e:  # noqa: BLE001
        res.append((FAIL, f"gagal uji fusion: {type(e).__name__}: {e}"))
    return res


SMOKE = {"do_soft_sensor": smoke_do, "ph_strip": smoke_ph, "cv_water_visual": smoke_cv, "risk_fusion": smoke_fusion}


# --------------------------------------------------------------------------- main
def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--model", help="hanya periksa satu model id")
    ap.add_argument("--load", action="store_true", help="coba muat model & jalankan uji ringan")
    ap.add_argument("--checksums", action="store_true", help="tulis CHECKSUMS.txt")
    args = ap.parse_args()

    reg = yaml.safe_load((ROOT / "models.yaml").read_text(encoding="utf-8"))
    failures = 0
    checksum_lines: list[str] = []

    for mid, spec in reg["models"].items():
        if args.model and args.model != mid:
            continue
        art_dir = ROOT / spec["artifact_dir"]
        print(f"\n=== {mid}  ({spec['title']})  status={spec['status']}  dir={spec['artifact_dir']}")
        for group in ("required", "recommended", "optional", "fallback", "benchmark_optional"):
            for art in spec["artifacts"].get(group, []):
                p = art_dir / art["file"]
                if p.exists():
                    problem = check_json(p) if p.suffix == ".json" else None
                    if problem:
                        print(f"  {FAIL} {group:<18} {art['file']}  -> {problem}")
                        failures += 1 if group == "required" else 0
                    else:
                        print(f"  {OK} {group:<18} {art['file']}  ({human(p.stat().st_size)})")
                        checksum_lines.append(f"{sha256(p)}  {spec['artifact_dir']}/{art['file']}")
                else:
                    tag = FAIL if group == "required" else (WARN if group == "recommended" else "[ -- ]")
                    print(f"  {tag} {group:<18} {art['file']}  (belum ada)")
                    if group == "required":
                        failures += 1

        if args.load and mid in SMOKE:
            print("  -- uji muat/ringan --")
            for tag, msg in SMOKE[mid](art_dir, spec):
                print(f"  {tag} {msg}")
                if tag == FAIL:
                    failures += 1

    if args.checksums and checksum_lines:
        (ROOT / "CHECKSUMS.txt").write_text("\n".join(sorted(checksum_lines)) + "\n", encoding="utf-8")
        print(f"\nCHECKSUMS.txt ditulis ({len(checksum_lines)} file).")

    print("\n" + ("SEMUA ARTEFAK WAJIB ADA." if failures == 0 else f"{failures} masalah pada artefak wajib - lihat [FAIL] di atas."))
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
