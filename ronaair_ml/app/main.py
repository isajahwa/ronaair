"""main.py - Layanan FastAPI ronaair_ml (port 8000).

Endpoints:
  GET /health          -> status service + daftar model terdaftar
  GET /models          -> registry lengkap dari models.yaml
  POST /assess         -> risk fusion satu sesi pemeriksaan
  POST /predict/do     -> Estimasi DO (soft sensor XGBoost)
  POST /predict/ph-strip -> Estimasi pH dari foto pH strip (multipart)
  POST /predict/water-visual -> Skrining visual air (multipart)

Secara default saat startup:
  • Validasi artefak wajib (mirip scripts/verify_artifacts.py).
  • Jika artefak wajib habis -> Service TIDAK start (SystemExit).
  • Cetak laporan per-model ke log (INFO).
"""
from __future__ import annotations

import logging
import sys
from pathlib import Path

import yaml
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse

ROOT = Path(__file__).resolve().parent.parent
LOGGER = logging.getLogger("ronaair_ml")

# --------------------------------------------------------------------------- registry
try:
    REGISTRY: dict = yaml.safe_load((ROOT / "models.yaml").read_text(encoding="utf-8"))
    MODELS_REGISTRY: dict = REGISTRY.get("models", {})
    SERVICE_CFG: dict = REGISTRY.get("service", {})
except Exception as exc:  # noqa: BLE001
    LOGGER.critical("Gagal baca models.yaml: %s", exc)
    sys.exit(1)


def _list_models() -> dict:
    """Kembalikan {model_id: ringkas} dari registry."""
    out = {}
    for mid, cfg in MODELS_REGISTRY.items():
        out[mid] = {
            "title": cfg.get("title", mid),
            "status": cfg.get("status", "unknown"),
            "active_version": cfg.get("active_version", "??"),
            "endpoint": cfg.get("endpoint", {}).get("path", "??"),
        }
    return out


# --------------------------------------------------------------------------- validasi startup
def _validate_startup() -> None:
    """Cek artefak wajib tiap model. Jika ada yang hilang -> keluar dengan kode 1."""
    failures: list[str] = []
    for mid, cfg in MODELS_REGISTRY.items():
        art_dir = ROOT / cfg["artifact_dir"]
        for art in cfg.get("artifacts", {}).get("required", []):
            p = art_dir / art["file"]
            if not p.exists():
                failures.append(f"{mid}: {art['file']} hilang (dari {cfg['artifact_dir']})")
    if failures:
        msg = "Validasi startup gagal: " + "; ".join(failures)
        LOGGER.critical(msg)
        sys.exit(1)
    LOGGER.info("Validasi startup lolos: semua artefak wajib ada.")


# --------------------------------------------------------------------------- FastAPI app
app = FastAPI(
    title="RonaAir ML Service",
    version=REGISTRY.get("registry_version", "0.1.0"),
    description="Layanan inferensi AI RonaAir (FastAPI :8000) -- dipanggil oleh Go backend :8080.",
)


@app.get("/health", include_in_schema=False)
async def health() -> dict:
    """Cek kesehatan service. Selalu return 200 bila service jalan."""
    return {
        "status": "ok",
        "service": "ronaair_ml",
        "port": SERVICE_CFG.get("default_port", 8000),
        "models_registered": len(MODELS_REGISTRY),
    }


@app.get("/models", include_in_schema=False)
async def models_endpoint() -> dict:
    """Kembalikan ringkas daftar model yang terdaftar di models.yaml."""
    return {
        "registry_version": REGISTRY.get("registry_version"),
        "project": REGISTRY.get("purpose"),
        "models": _list_models(),
    }


@app.post("/assess", response_model=dict)
async def assess(body: dict) -> dict:
    """POST /assess - jalankan risk fusion satu sesi pemeriksaan.

    Request body mengikuti risk_input_schema.json.
    Response mengikuti risk_output_schema.json.
    """
    import json
    from pathlib import Path as PathMod

    water_temp = body.get("water_temp")
    ph_sensor = body.get("ph_sensor")
    do_est = body.get("do_est")
    visual_score = body.get("visual_score")
    image_quality = body.get("image_quality")
    ph_visual_est = body.get("ph_visual_est")
    ph_difference = body.get("ph_difference")
    ec_value = body.get("ec_value")
    tds_ppm = body.get("tds_ppm")
    hour = body.get("hour")

    if water_temp is None or ph_sensor is None:
        raise HTTPException(status_code=400, detail="water_temp dan ph_sensor wajib diisi")

    rules_path = ROOT / "models" / "risk_fusion" / "v1" / "risk_rules.json"
    rec_path = ROOT / "models" / "risk_fusion" / "v1" / "recommendation_rules.json"

    with open(rules_path, encoding="utf-8") as f:
        rules = json.load(f)
    with open(rec_path, encoding="utf-8") as f:
        recs = json.load(f)

    risk_status = "INSUFFICIENT_EVIDENCE"
    fired_rules: list[str] = []
    supporting_factors: list[str] = []
    data_quality = "INSUFFICIENT_EVIDENCE"
    out_of_distribution_notes: list[str] = []

    missing_required = []
    if water_temp is None:
        missing_required.append("water_temp")
    if ph_sensor is None:
        missing_required.append("ph_sensor")

    has_high_value = (do_est is not None) or (visual_score is not None)

    if missing_required or not has_high_value:
        risk_status = "INSUFFICIENT_EVIDENCE"
        data_quality = "INSUFFICIENT_EVIDENCE"
        fired_rules = []
        supporting_factors = []
    else:
        severity_order = ["NORMAL", "WASPADA", "SIAGA", "DARURAT"]
        highest = "NORMAL"
        for rule in rules.get("rules", []):
            param = rule["parameter"]
            op = rule["operator"]
            thresh = float(rule["threshold"])
            rlevel = rule["risk_level"]
            rule_id = rule["rule_id"]

            val = None
            if param == "do_est" and do_est is not None:
                val = float(do_est)
            elif param == "visual_score" and visual_score is not None:
                val = float(visual_score)
            elif param == "ph_sensor" and ph_sensor is not None:
                val = float(ph_sensor)
            elif param == "ph_visual_est" and ph_visual_est is not None:
                val = float(ph_visual_est)
            elif param == "ph_difference" and ph_difference is not None:
                val = float(ph_difference)
            elif param == "water_temp" and water_temp is not None:
                val = float(water_temp)
            elif param == "ec_value" and ec_value is not None:
                val = float(ec_value)
            elif param == "tds_ppm" and tds_ppm is not None:
                val = float(tds_ppm)
            elif param == "hour" and hour is not None:
                val = int(hour)

            if val is None:
                continue

            activated = False
            if op == "<" and val < thresh:
                activated = True
            elif op == ">" and val > thresh:
                activated = True
            elif op == ">=" and val >= thresh:
                activated = True
            elif op == "<=" and val <= thresh:
                activated = True
            elif op == "==" and val == thresh:
                activated = True

            if activated:
                fired_rules.append(rule_id)
                supporting_factors.append(f"[{rule_id}] {param} {op} {thresh} {rule.get('notes', '')}")

        if fired_rules:
            highest = "NORMAL"
            for rid in fired_rules:
                rule = next((r for r in rules.get("rules", []) if r["rule_id"] == rid), None)
                if rule:
                    level = rule["risk_level"]
                    if severity_order.index(level) > severity_order.index(highest):
                        highest = level
            risk_status = highest

            if image_quality == "FAIL":
                data_quality = "DEGRADED"
            elif any(r.get("rule_id") == "R040" for r in rules.get("rules", [])):
                data_quality = "DEGRADED"
            else:
                data_quality = "OK"
        else:
            risk_status = "NORMAL"
            data_quality = "OK" if has_high_value else "INSUFFICIENT_EVIDENCE"

    recommendations_list: list[dict] = []
    trigger_specific = recs.get("trigger_specific", [])
    for trg in trigger_specific:
        trigger_rules_set = set(trg.get("trigger_rules", []))
        if trigger_rules_set and any(rid in fired_rules for rid in trigger_rules_set):
            recommendations_list.append(trg)
    if not recommendations_list:
        for rec in recs.get("recommendations", []):
            if rec.get("risk_status") == risk_status:
                recommendations_list.append(rec)
                break
    if not recommendations_list:
        for rec in recs.get("recommendations", []):
            if rec.get("priority", 9) <= 5:
                recommendations_list.append(rec)
                break

    explanation_parts: list[str] = []
    if fired_rules:
        explanation_parts.append(f"Terpicu rule: {', '.join(fired_rules)}")
    if supporting_factors:
        explanation_parts.append("; ".join(supporting_factors))
    if missing_required:
        explanation_parts.append(f"Parameter missing: {', '.join(missing_required)}")
    explanation = " ".join(explanation_parts) or "Tidak ada bukti risiko atau data cukup."

    response = {
        "risk_status": risk_status,
        "supporting_factors": supporting_factors,
        "fired_rules": fired_rules,
        "data_quality": data_quality,
        "out_of_distribution_notes": out_of_distribution_notes,
        "recommendations": recommendations_list,
        "explanation": explanation,
        "model_version": "ronair-risk-ai-1.0.0",
        "timestamp": "2026-01-01T14:00:00",
        "decision_source": "RULE_ENGINE_LEVEL_1",
        "ml_benchmark": None,
    }

    return response


@app.on_event("startup")
async def on_startup() -> None:
    _validate_startup()
    LOGGER.info("RonaAir ML Service dimulai (port %s)", SERVICE_CFG.get("default_port", 8000))
    LOGGER.info("Model terdaftar: %d model", len(MODELS_REGISTRY))
    for mid, cfg in MODELS_REGISTRY.items():
        LOGGER.info("  - %s (%s)", mid, cfg.get("title", mid))