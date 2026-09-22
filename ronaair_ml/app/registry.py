"""registry.py - Baca models.yaml dan berikan kontrak endpoint/artefak."""

from __future__ import annotations

from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent

# --- Load sekali saat import ---
try:
    _REGISTRY: dict = yaml.safe_load((ROOT / "models.yaml").read_text(encoding="utf-8"))
    _MODELS: dict = _REGISTRY.get("models", {})
    _SERVICE: dict = _REGISTRY.get("service", {})
except Exception as exc:  # noqa: BLE001
    raise RuntimeError(f"Gagal membaca models.yaml: {exc}") from exc


def get_registry() -> dict:
    """Kembalikan dictionary lengkap models.yaml."""
    return _REGISTRY


def get_models() -> dict:
    """Kembalikan dict {model_id: konfigurasi} dari models.yaml."""
    return _MODELS


def get_service_cfg() -> dict:
    """Kembalikan konfigurasi service (port, framework, dst.)."""
    return _SERVICE


def get_model(mid: str) -> dict | None:
    """Kembalikan konfigurasi satu model berdasarkan id."""
    return _MODELS.get(mid)


def list_models() -> dict:
    """Kembalikan ringkas daftar model: {id: {title, status, active_version, endpoint}}."""
    out: dict = {}
    for mid, cfg in _MODELS.items():
        out[mid] = {
            "title": cfg.get("title", mid),
            "status": cfg.get("status", "unknown"),
            "active_version": cfg.get("active_version", "??"),
            "endpoint": cfg.get("endpoint", {}).get("path", "??"),
        }
    return out


def get_endpoint(model_id: str) -> dict | None:
    """Kembalikan detail endpoint untuk model tertentu."""
    cfg = _MODELS.get(model_id)
    if cfg is None:
        return None
    endpoint = cfg.get("endpoint", {})
    return {
        "method": endpoint.get("method", "GET"),
        "path": endpoint.get("path", ""),
        "content_type": endpoint.get("content_type", "application/json"),
    }


def get_pipeline_order() -> list[str]:
    """Kembalikan urutan eksekusi pipeline dari models.yaml."""
    return _REGISTRY.get("pipeline", {}).get("order", ["do_soft_sensor", "ph_strip", "cv_water_visual", "risk_fusion"])