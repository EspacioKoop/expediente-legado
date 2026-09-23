#!/usr/bin/env python3
"""Valida y compara los benchmarks de fachadas vivas (#861) y animación ambiental (#1230)."""
from __future__ import annotations

import argparse
import json
import math
import tempfile
import unittest
from pathlib import Path
from typing import Any

REQUIRED_METRICS = (
    "draw_calls",
    "objects",
    "primitives",
    "process_ms",
    "static_memory_bytes",
)
PROCESS_BUDGET_PERCENT = 10.0
PROCESS_ABS_TOLERANCE_MS = 0.20
VALID_MODES = {"baseline", "full", "ambiental_baseline", "ambiental_full"}


def load_report(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema") != 1:
        raise ValueError(f"{path}: schema inesperado")
    if data.get("mode") not in VALID_MODES:
        raise ValueError(f"{path}: mode inválido")
    if data.get("resolution") != [1280, 720]:
        raise ValueError(f"{path}: resolución no canónica")
    if int(data.get("warmup_frames", 0)) <= 0 or int(data.get("sample_frames", 0)) <= 0:
        raise ValueError(f"{path}: muestreo inválido")
    metrics = data.get("metrics_avg")
    if not isinstance(metrics, dict):
        raise ValueError(f"{path}: falta metrics_avg")
    for key in REQUIRED_METRICS:
        value = metrics.get(key)
        if not isinstance(value, (int, float)) or not math.isfinite(value) or value < 0:
            raise ValueError(f"{path}: métrica inválida {key}={value!r}")
    if metrics["draw_calls"] <= 0:
        raise ValueError(f"{path}: draw_calls debe ser > 0")
    return data


def compare_reports(baseline: dict[str, Any], full: dict[str, Any]) -> dict[str, Any]:
    for key in ("resolution", "warmup_frames", "sample_frames", "camera"):
        if baseline.get(key) != full.get(key):
            raise ValueError(f"configuración no comparable: {key}")

    deltas: dict[str, dict[str, float | None]] = {}
    for metric in REQUIRED_METRICS:
        base = float(baseline["metrics_avg"][metric])
        current = float(full["metrics_avg"][metric])
        delta = current - base
        percent = None if base == 0 else (delta / base) * 100.0
        deltas[metric] = {
            "baseline": base,
            "full": current,
            "delta": delta,
            "percent": percent,
        }

    base_process = float(baseline["metrics_avg"]["process_ms"])
    full_process = float(full["metrics_avg"]["process_ms"])
    allowed_delta = max(
        base_process * (PROCESS_BUDGET_PERCENT / 100.0), PROCESS_ABS_TOLERANCE_MS
    )
    process_delta = full_process - base_process

    return {
        "schema": 1,
        "baseline_mode": baseline.get("mode"),
        "full_mode": full.get("mode"),
        "baseline_components": baseline.get("components", []),
        "full_components": full.get("components", []),
        "feature_counts": full.get("feature_counts", {}),
        "deltas": deltas,
        "budget": {
            "metric": "process_ms",
            "percent": PROCESS_BUDGET_PERCENT,
            "absolute_tolerance_ms": PROCESS_ABS_TOLERANCE_MS,
            "allowed_delta_ms": allowed_delta,
            "observed_delta_ms": process_delta,
            "passed": process_delta <= allowed_delta,
        },
        "gpu_frame_ms": None,
        "gpu_frame_ms_note": full.get("gpu_frame_ms_note", "N/D"),
    }


def format_report(
    summary: dict[str, Any],
    *,
    title: str = "# Benchmark fachadas vivas · #861",
    intro: str = "Comparación baseline/full sobre la misma cámara, resolución y número de frames.",
    baseline_label: str = "Baseline",
    full_label: str = "Fachadas vivas",
    feature_text: str | None = None,
) -> str:
    rows = []
    for metric in REQUIRED_METRICS:
        item = summary["deltas"][metric]
        percent = "N/D" if item["percent"] is None else f"{item['percent']:+.2f}%"
        rows.append(
            f"| {metric} | {item['baseline']:.3f} | {item['full']:.3f} | "
            f"{item['delta']:+.3f} | {percent} |"
        )
    budget = summary["budget"]
    status = "PASS" if budget["passed"] else "FAIL"
    counts = summary.get("feature_counts", {})
    if feature_text is None:
        feature_text = (
            f"Feature: {int(counts.get('grupos', 0))} ventanas / "
            f"{int(counts.get('render_batches', 0))} lotes MultiMesh / "
            f"{int(counts.get('batched_instances', 0))} instancias."
        )
    return "\n".join(
        [
            title,
            "",
            intro,
            "",
            f"| Métrica | {baseline_label} | {full_label} | Δ | Δ % |",
            "| --- | ---: | ---: | ---: | ---: |",
            *rows,
            "",
            f"Presupuesto process_ms: **{status}** · Δ observado "
            f"{budget['observed_delta_ms']:+.3f} ms · permitido "
            f"{budget['allowed_delta_ms']:.3f} ms.",
            feature_text,
            f"GPU frame time: {summary.get('gpu_frame_ms_note', 'N/D')}",
            "",
            "El runner usa render software; el gate compara únicamente ejecuciones del mismo entorno. "
            "La tolerancia absoluta de 0,20 ms evita falsos negativos cuando el baseline es muy bajo.",
        ]
    ) + "\n"


def _validate_screenshots(directory: Path, modes: tuple[str, str]) -> None:
    for mode in modes:
        screenshot = directory / f"{mode}.png"
        if not screenshot.is_file() or screenshot.stat().st_size <= 0:
            raise ValueError(f"captura ausente o vacía: {screenshot}")


def validate_artifacts(directory: Path) -> tuple[dict[str, Any], str]:
    baseline = load_report(directory / "baseline.json")
    full = load_report(directory / "full.json")
    _validate_screenshots(directory, ("baseline", "full"))
    summary = compare_reports(baseline, full)
    markdown = format_report(summary)
    (directory / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (directory / "report.md").write_text(markdown, encoding="utf-8")
    return summary, markdown


def validate_ambiental_artifacts(directory: Path) -> tuple[dict[str, Any], str]:
    baseline = load_report(directory / "ambiental_baseline.json")
    full = load_report(directory / "ambiental_full.json")
    _validate_screenshots(directory, ("ambiental_baseline", "ambiental_full"))
    summary = compare_reports(baseline, full)
    baseline_components = set(summary.get("baseline_components", []))
    full_components = set(summary.get("full_components", []))
    if "animacion_ambiental" in baseline_components:
        raise ValueError("ambiental_baseline no debe activar animación ambiental")
    if full_components - {"animacion_ambiental"} != baseline_components:
        raise ValueError("la pareja ambiental no comparte la misma geometría base")
    if "animacion_ambiental" not in full_components:
        raise ValueError("ambiental_full no activó la capa ambiental")

    counts = summary.get("feature_counts", {})
    for key in ("animated_windows", "wind_materials", "active_pieces"):
        if int(counts.get(key, 0)) <= 0:
            raise ValueError(f"benchmark ambiental vacío: {key}=0")
    feature_text = (
        f"Feature ambiental: {int(counts.get('animated_windows', 0))} ventanas animadas / "
        f"{int(counts.get('wind_materials', 0))} materiales de follaje / "
        f"{int(counts.get('active_pieces', 0))} piezas activas."
    )
    markdown = format_report(
        summary,
        title="# Benchmark animación ambiental · #1230",
        intro=(
            "Comparación ambiental_baseline/ambiental_full con fachadas y arbolado "
            "idénticos; solo la segunda activa planificador, ventanas y viento."
        ),
        baseline_label="Sin animación ambiental",
        full_label="Con animación ambiental",
        feature_text=feature_text,
    )
    (directory / "ambiental-summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (directory / "ambiental-report.md").write_text(markdown, encoding="utf-8")
    return summary, markdown


class BenchmarkFachadasComparisonTest(unittest.TestCase):
    def _fixture(self, mode: str, process_ms: float = 2.0) -> dict[str, Any]:
        full_like = mode in {"full", "ambiental_baseline", "ambiental_full"}
        return {
            "schema": 1,
            "mode": mode,
            "resolution": [1280, 720],
            "warmup_frames": 90,
            "sample_frames": 180,
            "camera": {
                "position": [0.0, 1.65, -7.4],
                "target": [-5.25, 5.8, -12.2],
                "fov": 68.0,
            },
            "components": (
                ["trayecto", "calle_identidad", "fachadas_vivas", "arboles_cc0", "animacion_ambiental"]
                if mode == "ambiental_full"
                else (
                    ["trayecto", "calle_identidad", "fachadas_vivas", "arboles_cc0"]
                    if mode == "ambiental_baseline"
                    else ["trayecto", "calle_identidad"]
                )
            ),
            "feature_counts": {
                "grupos": 61 if full_like else 0,
                "render_batches": 17 if full_like else 0,
                "batched_instances": 145 if full_like else 0,
            },
            "metrics_avg": {
                "draw_calls": 20.0 if mode == "baseline" else 25.0,
                "objects": 30.0,
                "primitives": 300.0,
                "process_ms": process_ms,
                "static_memory_bytes": 1000.0,
            },
            "gpu_frame_ms_note": "N/D",
        }

    def test_budget_accepts_delta_under_ten_percent(self) -> None:
        summary = compare_reports(self._fixture("baseline", 3.0), self._fixture("full", 3.25))
        self.assertTrue(summary["budget"]["passed"])

    def test_budget_rejects_clear_regression(self) -> None:
        summary = compare_reports(self._fixture("baseline", 3.0), self._fixture("full", 3.5))
        self.assertFalse(summary["budget"]["passed"])

    def test_absolute_tolerance_handles_tiny_baseline(self) -> None:
        summary = compare_reports(self._fixture("baseline", 0.5), self._fixture("full", 0.65))
        self.assertTrue(summary["budget"]["passed"])
        self.assertEqual(PROCESS_ABS_TOLERANCE_MS, summary["budget"]["allowed_delta_ms"])

    def test_mismatched_camera_is_rejected(self) -> None:
        baseline = self._fixture("baseline")
        full = self._fixture("full")
        full["camera"] = {"position": [1.0, 2.0, -14.0]}
        with self.assertRaisesRegex(ValueError, "camera"):
            compare_reports(baseline, full)

    def test_artifacts_are_materialized(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            for mode in ("baseline", "full"):
                (directory / f"{mode}.json").write_text(
                    json.dumps(self._fixture(mode)), encoding="utf-8"
                )
                (directory / f"{mode}.png").write_bytes(b"png")
            summary, markdown = validate_artifacts(directory)
            self.assertIn("draw_calls", summary["deltas"])
            self.assertIn("61 ventanas / 17 lotes MultiMesh / 145 instancias", markdown)
            self.assertTrue((directory / "summary.json").is_file())
            self.assertTrue((directory / "report.md").is_file())

    def test_ambiental_uses_the_same_budget_and_apparatus(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            baseline = self._fixture("ambiental_baseline", 3.0)
            full = self._fixture("ambiental_full", 3.2)
            baseline["feature_counts"].update(
                {"animated_windows": 0, "wind_materials": 0, "active_pieces": 0}
            )
            full["feature_counts"].update(
                {"render_batches": 18, "batched_instances": 163,
                 "animated_windows": 18, "wind_materials": 3, "active_pieces": 19}
            )
            for mode, report in (
                ("ambiental_baseline", baseline),
                ("ambiental_full", full),
            ):
                (directory / f"{mode}.json").write_text(
                    json.dumps(report), encoding="utf-8"
                )
                (directory / f"{mode}.png").write_bytes(b"png")
            summary, markdown = validate_ambiental_artifacts(directory)
            self.assertTrue(summary["budget"]["passed"])
            self.assertIn("Benchmark animación ambiental · #1230", markdown)
            self.assertIn("18 ventanas animadas", markdown)
            self.assertTrue((directory / "ambiental-summary.json").is_file())
            self.assertTrue((directory / "ambiental-report.md").is_file())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    summary, markdown = validate_artifacts(args.report)
    ambiental_summary, ambiental_markdown = validate_ambiental_artifacts(args.report)
    print(markdown, end="")
    print("\n" + ambiental_markdown, end="")

    for nombre, resultado in (
        ("fachadas", summary),
        ("animación ambiental", ambiental_summary),
    ):
        if resultado["budget"]["passed"]:
            continue
        budget = resultado["budget"]
        raise SystemExit(
            f"regresión de process_ms fuera de presupuesto ({nombre}): "
            f"{budget['observed_delta_ms']:+.3f} ms > {budget['allowed_delta_ms']:.3f} ms"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
