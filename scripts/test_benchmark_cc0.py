#!/usr/bin/env python3
"""Valida y compara los artefactos producidos por benchmark_cc0.gd."""
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


def load_report(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema") != 1:
        raise ValueError(f"{path}: schema inesperado")
    if data.get("mode") not in {"baseline", "retro_urban", "full"}:
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
    return {
        "schema": 1,
        "target_mode": full.get("mode", "full"),
        "baseline_components": baseline.get("components", []),
        "full_components": full.get("components", []),
        "deltas": deltas,
        "gpu_frame_ms": None,
        "gpu_frame_ms_note": full.get("gpu_frame_ms_note", "N/D"),
    }


def format_report(summary: dict[str, Any]) -> str:
    target_mode = summary.get("target_mode", "full")
    target_label = "Retro Urban aislado" if target_mode == "retro_urban" else "CC0 completo"
    title = (
        "# Benchmark Retro Urban · trayecto"
        if target_mode == "retro_urban"
        else "# Benchmark CC0 · trayecto"
    )
    rows = []
    for metric in REQUIRED_METRICS:
        item = summary["deltas"][metric]
        percent = "N/D" if item["percent"] is None else f"{item['percent']:+.2f}%"
        rows.append(
            f"| {metric} | {item['baseline']:.3f} | {item['full']:.3f} | "
            f"{item['delta']:+.3f} | {percent} |"
        )
    return "\n".join(
        [
            title,
            "",
            "Comparación reproducible sobre la misma cámara, resolución y número de frames.",
            "",
            f"| Métrica | Baseline | {target_label} | Δ | Δ % |",
            "| --- | ---: | ---: | ---: | ---: |",
            *rows,
            "",
            f"GPU frame time: {summary.get('gpu_frame_ms_note', 'N/D')}",
            "",
            "Las cifras del runner software sirven para detectar cambios relativos en el mismo entorno; "
            "no son un objetivo de FPS para hardware de jugador.",
        ]
    ) + "\n"


def validate_artifacts(directory: Path) -> tuple[dict[str, Any], str]:
    baseline = load_report(directory / "baseline.json")
    retro_urban = load_report(directory / "retro_urban.json")
    full = load_report(directory / "full.json")
    for mode in ("baseline", "retro_urban", "full"):
        screenshot = directory / f"{mode}.png"
        if not screenshot.is_file() or screenshot.stat().st_size <= 0:
            raise ValueError(f"captura ausente o vacía: {screenshot}")

    summary = compare_reports(baseline, full)
    retro_summary = compare_reports(baseline, retro_urban)
    markdown = format_report(summary)
    retro_markdown = format_report(retro_summary)
    (directory / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (directory / "report.md").write_text(markdown, encoding="utf-8")
    (directory / "retro_urban-summary.json").write_text(
        json.dumps(retro_summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (directory / "retro_urban-report.md").write_text(retro_markdown, encoding="utf-8")
    return summary, markdown + "\n" + retro_markdown


class BenchmarkComparisonTest(unittest.TestCase):
    def _fixture(self, mode: str, draw_calls: float) -> dict[str, Any]:
        return {
            "schema": 1,
            "mode": mode,
            "resolution": [1280, 720],
            "warmup_frames": 90,
            "sample_frames": 180,
            "camera": {"position": [0, 2, -14], "target": [0, 1.25, 5], "fov": 68},
            "components": ["trayecto"],
            "metrics_avg": {
                "draw_calls": draw_calls,
                "objects": 10.0,
                "primitives": 100.0,
                "process_ms": 2.0,
                "static_memory_bytes": 1000.0,
            },
            "gpu_frame_ms_note": "N/D",
        }

    def test_delta_is_computed(self) -> None:
        summary = compare_reports(self._fixture("baseline", 10), self._fixture("full", 15))
        self.assertEqual(5.0, summary["deltas"]["draw_calls"]["delta"])
        self.assertEqual(50.0, summary["deltas"]["draw_calls"]["percent"])

    def test_mismatched_camera_is_rejected(self) -> None:
        baseline = self._fixture("baseline", 10)
        full = self._fixture("full", 15)
        full["camera"] = {"position": [1, 2, -14]}
        with self.assertRaisesRegex(ValueError, "camera"):
            compare_reports(baseline, full)

    def test_artifacts_are_materialized(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            for mode, draw_calls in (("baseline", 10), ("retro_urban", 12), ("full", 15)):
                (directory / f"{mode}.json").write_text(
                    json.dumps(self._fixture(mode, draw_calls)), encoding="utf-8"
                )
                (directory / f"{mode}.png").write_bytes(b"png")
            summary, markdown = validate_artifacts(directory)
            self.assertIn("draw_calls", summary["deltas"])
            self.assertIn("Benchmark CC0", markdown)
            self.assertIn("Benchmark Retro Urban", markdown)
            self.assertTrue((directory / "summary.json").is_file())
            self.assertTrue((directory / "report.md").is_file())
            self.assertTrue((directory / "retro_urban-summary.json").is_file())
            self.assertTrue((directory / "retro_urban-report.md").is_file())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    _, markdown = validate_artifacts(args.report)
    print(markdown, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
