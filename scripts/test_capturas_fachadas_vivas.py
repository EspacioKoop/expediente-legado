#!/usr/bin/env python3
"""Valida la comparación visual de FachadasVivas desde la ruta jugable (#861)."""
from __future__ import annotations

import argparse
import json
import tempfile
import unittest
from pathlib import Path
from typing import Any

EXPECTED_STATIONS = ("cerca", "media", "lejos")


def load_manifest(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema") != 1:
        raise ValueError(f"{path}: schema inesperado")
    if data.get("mode") not in {"baseline", "full"}:
        raise ValueError(f"{path}: mode inválido")
    if data.get("resolution") != [1280, 720]:
        raise ValueError(f"{path}: resolución no canónica")
    if float(data.get("fov", 0.0)) <= 0:
        raise ValueError(f"{path}: FOV inválido")
    stations = data.get("stations")
    if not isinstance(stations, list):
        raise ValueError(f"{path}: falta stations")
    ids = tuple(item.get("id") for item in stations if isinstance(item, dict))
    if ids != EXPECTED_STATIONS:
        raise ValueError(f"{path}: estaciones inesperadas {ids!r}")
    for station in stations:
        if not isinstance(station.get("position"), list) or len(station["position"]) != 3:
            raise ValueError(f"{path}: posición inválida en {station.get('id')}")
        if not isinstance(station.get("target"), list) or len(station["target"]) != 3:
            raise ValueError(f"{path}: objetivo inválido en {station.get('id')}")
        if float(station.get("distance_m", 0.0)) <= 0:
            raise ValueError(f"{path}: distancia inválida en {station.get('id')}")
        if not isinstance(station.get("screenshot"), str) or not station["screenshot"]:
            raise ValueError(f"{path}: screenshot inválido en {station.get('id')}")
    return data


def compare_manifests(baseline: dict[str, Any], full: dict[str, Any]) -> list[dict[str, Any]]:
    for key in ("resolution", "fov", "stabilization_frames"):
        if baseline.get(key) != full.get(key):
            raise ValueError(f"configuración visual no comparable: {key}")

    pairs: list[dict[str, Any]] = []
    for base_station, full_station in zip(baseline["stations"], full["stations"], strict=True):
        if base_station["id"] != full_station["id"]:
            raise ValueError("estaciones baseline/full desalineadas")
        for key in ("position", "target", "distance_m"):
            if base_station.get(key) != full_station.get(key):
                raise ValueError(
                    f"estación {base_station['id']} no comparable: {key}"
                )
        pairs.append(
            {
                "id": base_station["id"],
                "distance_m": float(base_station["distance_m"]),
                "baseline": base_station["screenshot"],
                "full": full_station["screenshot"],
            }
        )
    return pairs


def validate_artifacts(directory: Path) -> tuple[list[dict[str, Any]], str]:
    baseline = load_manifest(directory / "baseline-ruta.json")
    full = load_manifest(directory / "full-ruta.json")
    pairs = compare_manifests(baseline, full)

    for pair in pairs:
        for key in ("baseline", "full"):
            screenshot = directory / pair[key]
            if not screenshot.is_file() or screenshot.stat().st_size <= 0:
                raise ValueError(f"captura ausente o vacía: {screenshot}")

    rows = [
        f"| {pair['id']} | {pair['distance_m']:.2f} m | `{pair['baseline']}` | `{pair['full']}` |"
        for pair in pairs
    ]
    markdown = "\n".join(
        [
            "# Evidencia visual de fachadas vivas · #861",
            "",
            "Baseline y FachadasVivas se capturan desde las mismas tres estaciones del eje jugable.",
            "",
            "| Estación | Distancia al tramo | Baseline | Fachadas vivas |",
            "| --- | ---: | --- | --- |",
            *rows,
            "",
            "Las capturas son evidencia reproducible para revisión; no sustituyen una validación visual humana en juego.",
        ]
    ) + "\n"
    (directory / "ruta-report.md").write_text(markdown, encoding="utf-8")
    return pairs, markdown


class CapturasFachadasVivasTest(unittest.TestCase):
    def _fixture(self, mode: str) -> dict[str, Any]:
        stations = []
        for index, station_id in enumerate(EXPECTED_STATIONS):
            stations.append(
                {
                    "id": station_id,
                    "position": [0.0, 1.65, float(index)],
                    "target": [-5.2, 5.8, -12.5],
                    "distance_m": 6.0 + index,
                    "screenshot": f"{mode}-ruta-{station_id}.png",
                }
            )
        return {
            "schema": 1,
            "mode": mode,
            "resolution": [1280, 720],
            "fov": 68.0,
            "stabilization_frames": 12,
            "components": ["trayecto", "calle_identidad"],
            "stations": stations,
        }

    def test_rejects_mismatched_station_camera(self) -> None:
        baseline = self._fixture("baseline")
        full = self._fixture("full")
        full["stations"][1]["position"] = [1.0, 1.65, 0.0]
        with self.assertRaisesRegex(ValueError, "posición|position"):
            compare_manifests(baseline, full)

    def test_requires_three_route_stations(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "baseline-ruta.json"
            fixture = self._fixture("baseline")
            fixture["stations"].pop()
            path.write_text(json.dumps(fixture), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "estaciones"):
                load_manifest(path)

    def test_artifacts_are_materialized(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            for mode in ("baseline", "full"):
                fixture = self._fixture(mode)
                (directory / f"{mode}-ruta.json").write_text(
                    json.dumps(fixture), encoding="utf-8"
                )
                for station in fixture["stations"]:
                    (directory / station["screenshot"]).write_bytes(b"png")
            pairs, markdown = validate_artifacts(directory)
            self.assertEqual(3, len(pairs))
            self.assertIn("cerca", markdown)
            self.assertTrue((directory / "ruta-report.md").is_file())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    _pairs, markdown = validate_artifacts(args.report)
    print(markdown, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
