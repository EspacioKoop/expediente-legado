#!/usr/bin/env python3
"""Auditor offline de los catálogos CSV y referencias estáticas de Godot 4.

Uso: python3 scripts/auditar_localizacion_20261016.py --root . --json reporte.json
Las traducciones *.translation proceden de importadores; no tienen que estar
versionadas. Solo lee el checkout local y nunca sigue enlaces externos.
"""
from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path

TRANSLATION = re.compile(
    r'\b(?:tr|TranslationServer\.translate)\s*\(\s*(&\s*)?(?P<arg>"[^"\n]*"|[^,\)\n]+)'
)
RESOURCE = re.compile(r'"(res://[^"\n]+\.translation)"')
IMPORT_FIELD = re.compile(r'(?m)^\s*(source_file|dest_files)\s*=\s*(.+)$')


def within(root: Path, path: Path) -> bool:
    return path.resolve().is_relative_to(root.resolve())


def finding(code: str, path: Path, line: int, detail: str, severity="error") -> dict:
    return {
        "code": code, "file": path.as_posix(), "line": line,
        "severity": severity, "detail": detail,
    }


def scan(root: Path) -> dict:
    root = root.resolve()
    game = root / "godot"
    if not game.is_dir() or not within(root, game):
        raise ValueError("La raíz debe contener el directorio godot")

    findings = []
    keys = set()
    catalogs = []
    for path in sorted((game / "datos").glob("*textos*.csv")):
        if not path.is_file() or not within(root, path):
            continue
        catalogs.append(path)
        rel = path.relative_to(root)
        with path.open(encoding="utf-8-sig", newline="") as source:
            reader = csv.reader(source)
            try:
                header = next(reader)
            except StopIteration:
                findings.append(finding("csv_empty", rel, 1, "CSV sin cabecera"))
                continue
            if len(header) < 2 or header[0].strip().lower() != "clave":
                findings.append(finding("csv_header", rel, 1, "Cabecera clave,es ausente"))
                continue
            seen = set()
            for row in reader:
                line = reader.line_num
                if not row or all(not value.strip() for value in row):
                    continue
                key = row[0].strip()
                if not key:
                    findings.append(finding("empty_key", rel, line, "Clave vacía"))
                    continue
                if key in seen:
                    findings.append(finding("duplicate_key", rel, line, key))
                seen.add(key)
                keys.add(key)
                if len(row) < 2 or not row[1].strip():
                    findings.append(finding("empty_translation", rel, line, key))

    files_scanned = 0
    for path in sorted(game.rglob("*")):
        if path.suffix not in {".gd", ".tscn", ".tres"}:
            continue
        if not path.is_file() or not within(root, path):
            continue
        files_scanned += 1
        rel = path.relative_to(root)
        for line_no, line in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
            if line.lstrip().startswith(("#", ";")):
                continue
            for match in TRANSLATION.finditer(line):
                arg = match.group("arg").strip()
                if arg.startswith('"') and arg.endswith('"'):
                    key = arg[1:-1]
                    if key and key not in keys:
                        findings.append(finding("missing_key", rel, line_no, key))
                else:
                    findings.append(finding(
                        "dynamic_key", rel, line_no,
                        "Clave dinámica: no demostrable estáticamente", "info",
                    ))

    project = game / "project.godot"
    if project.is_file() and within(root, project):
        for line_no, line in enumerate(project.read_text(encoding="utf-8-sig").splitlines(), 1):
            if line.lstrip().startswith(";"):
                continue
            for resource in RESOURCE.findall(line):
                target = game / resource.removeprefix("res://")
                if not within(root, target):
                    findings.append(finding(
                        "invalid_translation_path", project.relative_to(root),
                        line_no, resource,
                    ))
                    continue
                if target.is_file():
                    continue
                match = re.fullmatch(
                    r"(.+)\.[A-Za-z_-]+\.translation", target.name,
                )
                source = target.with_name(match.group(1) + ".csv") if match else None
                imported = Path(str(source) + ".import") if source else None
                valid = False
                if (source and imported and source.is_file() and imported.is_file()
                        and within(root, source) and within(root, imported)):
                    fields = dict(IMPORT_FIELD.findall(
                        imported.read_text(encoding="utf-8-sig")
                    ))
                    expected = "res://" + source.relative_to(game).as_posix()
                    valid = (expected in fields.get("source_file", "")
                             and resource in fields.get("dest_files", ""))
                if not valid:
                    findings.append(finding(
                        "unresolvable_translation", project.relative_to(root),
                        line_no, resource,
                    ))

    findings.sort(key=lambda x: (x["file"], x["line"], x["code"], x["detail"]))
    return {
        "schema": 1,
        "stats": {
            "catalogs": len(catalogs), "files_scanned": files_scanned,
            "keys": len(keys),
            "errors": sum(x["severity"] == "error" for x in findings),
        },
        "findings": findings,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--json", type=Path)
    args = parser.parse_args()
    result = scan(args.root)
    output = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.json:
        target = args.json.resolve()
        if not within(args.root.resolve(), target):
            parser.error("El informe debe guardarse dentro de --root")
        target.write_text(output, encoding="utf-8")
    else:
        print(output, end="")
    return int(result["stats"]["errors"] > 0)


if __name__ == "__main__":
    raise SystemExit(main())
