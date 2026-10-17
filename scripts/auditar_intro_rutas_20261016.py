#!/usr/bin/env python3
"""Auditor estático offline de referencias a escenas, recursos y disparadores de la secuencia de introducción (#395, #20261016).

Analiza archivos del proyecto Godot (.gd, .tscn, .json, .tres) para rastrear:
1. Rutas de recursos 'res://' y cargas dinámicas/estáticas.
2. Transiciones de escena (change_scene_to_file, etc.).
3. Disparadores de secuencias y cinemáticas introductorias.
4. Estado de existencia en disco de cada destino referenciado (confinado al repo).

Devuelve informe estructurado en JSON indicando origen, línea, referencia,
destino en disco, si existe, no existe o es indeterminado (rutas dinámicas),
y detalles de la incidencia.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import unittest
from pathlib import Path
from typing import Any

# Raíz canónica del repositorio (dos niveles arriba de scripts/)
REPO_ROOT = Path(__file__).resolve().parent.parent

# Extensiones de archivos fuente del proyecto protegidas contra sobreescritura accidental
EXTENSIONES_PROHIBIDAS_JSON_OUT = {".gd", ".tscn", ".tres", ".py", ".gdshader", ".uid", ".sh"}

# Match explicit res:// paths
RE_RES_PATH = re.compile(r'res://[a-zA-Z0-9_\-/.%*{}]+')

# Match preloads, loads, change_scene_to_file
RE_LOAD_PRELOAD = re.compile(
    r'(?P<func>preload|load|change_scene_to_file|change_scene_to_packed)\s*\(\s*["\'](?P<path>[^"\']+)["\']\s*\)'
)

# Match cutscene / intro triggers
RE_TRIGGER = re.compile(
    r'(?P<trigger>iniciar_apertura_creditos|iniciar_montaje_onirico|iniciar_cinematica_creditos|terminar_apertura_creditos|_iniciar_apertura_creditos|_iniciar_montaje_onirico|_iniciar_cinematica_creditos|_terminar_apertura_creditos|reproducir|planos_de|planos)\s*\('
)

# Patterns in filenames/paths related to intro cutscenes
PATRONES_INTRO = ("intro", "inicio", "apertura", "creditos", "epigrafes", "cinematica", "secuencia")


def es_ruta_dinamica(path_str: str) -> bool:
    """Devuelve True si la ruta contiene comodines o variables dinámicas (%s, *, {}, $)."""
    return any(c in path_str for c in ("%", "*", "{", "}", "$"))


def resolver_ruta_res(res_path: str) -> tuple[str, Path]:
    """Convierte una ruta res:// a ruta relativa al REPO_ROOT y objeto Path absoluto confinado."""
    if res_path.startswith("res://"):
        rel_str = "godot/" + res_path[6:]
    else:
        rel_str = res_path
    abs_path = (REPO_ROOT / rel_str).resolve()
    return rel_str, abs_path


def es_archivo_relacionado_intro(path: Path, contenido: str | None = None) -> bool:
    """Comprueba si un archivo pertenece a o está relacionado con la secuencia introductoria.

    Criterios de inclusión:
    1. El nombre o ruta del archivo contiene algún patrón de intro (PATRONES_INTRO).
    2. O el contenido incluye disparadores introductorios o cargas/transiciones a escenas de intro.
    """
    path_str = str(path).lower()
    if any(pat in path_str for pat in PATRONES_INTRO):
        return True

    if contenido is None and path.is_file():
        try:
            contenido = path.read_text(encoding="utf-8")
        except Exception:
            return False

    if contenido:
        if RE_TRIGGER.search(contenido):
            return True
        for m in RE_LOAD_PRELOAD.finditer(contenido):
            target = m.group("path").lower()
            if any(pat in target for pat in PATRONES_INTRO):
                return True

    return False


def validar_confinamiento_ruta(path: Path) -> tuple[bool, str, Path | None]:
    """Verifica que la ruta exista y esté strictly confinada dentro del REPO_ROOT sin escapar por traversal o symlinks."""
    try:
        abs_path = path.resolve(strict=True)
    except FileNotFoundError:
        return False, f"La ruta especificada no existe: {path}", None
    except Exception as exc:
        return False, f"Error al resolver la ruta '{path}': {exc}", None

    try:
        abs_path.relative_to(REPO_ROOT)
    except ValueError:
        return False, f"Acceso denegado: la ruta '{path}' está fuera de la raíz del repositorio ({REPO_ROOT})", None

    return True, "Ruta válida y confinada", abs_path


def validar_escritura_json_segura(json_out: Path) -> tuple[bool, str]:
    """Asegura que --json-out no sobreescriba archivos de código/escenas del repositorio."""
    try:
        resolved_out = json_out.resolve()
    except Exception:
        resolved_out = json_out.absolute()

    if resolved_out.suffix.lower() in EXTENSIONES_PROHIBIDAS_JSON_OUT:
        return False, f"Política de escritura segura: Prohibido sobreescribir archivos con extensión {resolved_out.suffix}"

    try:
        rel = resolved_out.relative_to(REPO_ROOT)
        parts = rel.parts
        if len(parts) > 0 and parts[0] in ("godot", "scripts"):
            return False, f"Política de escritura segura: No se permite sobreescribir ficheros dentro de '{parts[0]}'"
    except ValueError:
        # Fuera de REPO_ROOT (por ejemplo en /tmp o dist/) es seguro
        pass

    return True, "Ruta de exportación segura"


def auditar_archivo(ruta: Path) -> list[dict[str, Any]]:
    """Audita un único archivo e identifica referencias, cargas y disparadores."""
    try:
        contenido = ruta.read_text(encoding="utf-8")
    except Exception as exc:
        try:
            rel_origen = str(ruta.relative_to(REPO_ROOT))
        except ValueError:
            rel_origen = str(ruta)
        return [
            {
                "origen": rel_origen,
                "linea": 0,
                "origen_linea": "",
                "referencia_raw": "",
                "destino_calculado": "",
                "existe": False,
                "estado": "error_lectura",
                "tipo_referencia": "error_lectura",
                "detalles": f"No se pudo leer el archivo: {exc}",
            }
        ]

    try:
        rel_origen = str(ruta.relative_to(REPO_ROOT))
    except ValueError:
        rel_origen = str(ruta)

    hallazgos: list[dict[str, Any]] = []
    lineas = contenido.splitlines()

    for idx, raw_line in enumerate(lineas, start=1):
        line = raw_line.strip()
        if not line or line.startswith("#") or line.startswith("//"):
            continue

        # 1. Cargas explícitas / transiciones
        for m_load in RE_LOAD_PRELOAD.finditer(line):
            func_name = m_load.group("func")
            raw_path = m_load.group("path")
            rel_dest, abs_dest = resolver_ruta_res(raw_path)

            if es_ruta_dinamica(raw_path):
                existe: bool | None = None
                estado = "indeterminado"
            else:
                existe = abs_dest.exists()
                estado = "existe" if existe else "inexistente"

            tipo = "cambio_escena" if "change_scene" in func_name else "carga_recurso"
            hallazgos.append(
                {
                    "origen": rel_origen,
                    "linea": idx,
                    "origen_linea": line,
                    "referencia_raw": raw_path,
                    "destino_calculado": rel_dest,
                    "existe": existe,
                    "estado": estado,
                    "tipo_referencia": tipo,
                    "detalles": f"Llamada a {func_name} con referencia a '{raw_path}'",
                }
            )

        # 2. Rutas res:// generales en texto
        for m_res in RE_RES_PATH.finditer(line):
            raw_path = m_res.group(0)
            if any(h["referencia_raw"] == raw_path and h["linea"] == idx for h in hallazgos):
                continue

            rel_dest, abs_dest = resolver_ruta_res(raw_path)
            if es_ruta_dinamica(raw_path):
                existe = None
                estado = "indeterminado"
            else:
                existe = abs_dest.exists()
                estado = "existe" if existe else "inexistente"

            hallazgos.append(
                {
                    "origen": rel_origen,
                    "linea": idx,
                    "origen_linea": line,
                    "referencia_raw": raw_path,
                    "destino_calculado": rel_dest,
                    "existe": existe,
                    "estado": estado,
                    "tipo_referencia": "referencia_res",
                    "detalles": f"Referencia res:// {'dinámica/plantilla' if estado == 'indeterminado' else 'directa'}: {raw_path}",
                }
            )

        # 3. Disparadores de secuencia introductoria
        for m_trig in RE_TRIGGER.finditer(line):
            trigger_name = m_trig.group("trigger")
            hallazgos.append(
                {
                    "origen": rel_origen,
                    "linea": idx,
                    "origen_linea": line,
                    "referencia_raw": trigger_name,
                    "destino_calculado": rel_origen,
                    "existe": True,
                    "estado": "existe",
                    "tipo_referencia": "disparador_secuencia",
                    "detalles": f"Disparador de secuencia o cinemática introductoria: '{trigger_name}'",
                }
            )

    return hallazgos


def auditar_ruta(target_path: Path, solo_intro: bool = True) -> dict[str, Any]:
    """Audita una ruta objetivo (archivo o directorio) dentro del repositorio."""
    archivos: list[Path] = []
    if target_path.is_file():
        archivos.append(target_path)
    elif target_path.is_dir():
        for p in sorted(target_path.rglob("*")):
            if p.is_file() and p.suffix in (".gd", ".tscn", ".json", ".tres"):
                if not solo_intro or es_archivo_relacionado_intro(p):
                    archivos.append(p)

    todos_hallazgos: list[dict[str, Any]] = []
    for fpath in archivos:
        hallazgos = auditar_archivo(fpath)
        todos_hallazgos.extend(hallazgos)

    inexistentes = [h for h in todos_hallazgos if h["existe"] is False]
    existentes = [h for h in todos_hallazgos if h["existe"] is True]
    indeterminados = [h for h in todos_hallazgos if h["existe"] is None]

    archivos_str = []
    for a in archivos:
        try:
            archivos_str.append(str(a.relative_to(REPO_ROOT)))
        except ValueError:
            archivos_str.append(str(a))

    return {
        "vulnerabilidad_o_mision": "#395 / #20261016",
        "descripcion": "Rastreador estático offline de referencias a escenas y recursos de introducción y disparadores conocidos",
        "raiz_repositorio": str(REPO_ROOT),
        "total_archivos_auditados": len(archivos),
        "total_referencias_encontradas": len(todos_hallazgos),
        "total_referencias_existentes": len(existentes),
        "total_referencias_inexistentes": len(inexistentes),
        "total_referencias_indeterminadas": len(indeterminados),
        "limites_alcance": {
            "filtro_intro": solo_intro,
            "patrones_nombre": list(PATRONES_INTRO),
            "extensiones_soportadas": [".gd", ".tscn", ".json", ".tres"],
            "deteccion_llamadores_genericos": True,
        },
        "archivos_auditados": archivos_str,
        "hallazgos_inexistentes": inexistentes,
        "hallazgos_indeterminados": indeterminados,
        "todos_hallazgos": todos_hallazgos,
    }


class PruebasSelfTestAuditorIntro(unittest.TestCase):
    """Suite de pruebas unitarias integradas (--self-test)."""

    def setUp(self) -> None:
        self.tmp_dir = REPO_ROOT / "dist" / "tmp_test_fixtures"
        self.tmp_dir.mkdir(parents=True, exist_ok=True)

    def tearDown(self) -> None:
        import shutil
        if self.tmp_dir.exists():
            shutil.rmtree(self.tmp_dir, ignore_errors=True)

    def test_resolver_ruta_res_independiente_cwd(self) -> None:
        old_cwd = os.getcwd()
        try:
            os.chdir(REPO_ROOT / "scripts")
            rel, abs_path = resolver_ruta_res("res://escenas/inicio.tscn")
            self.assertEqual(rel, "godot/escenas/inicio.tscn")
            self.assertEqual(abs_path, (REPO_ROOT / "godot/escenas/inicio.tscn").resolve())
        finally:
            os.chdir(old_cwd)

    def test_ruta_dinamica_estado_indeterminado(self) -> None:
        test_file = self.tmp_dir / "test_dinamico_temp.gd"
        test_file.parent.mkdir(parents=True, exist_ok=True)
        try:
            test_file.write_text('var p = "res://escenas/%s.tscn"\n', encoding="utf-8")
            hallazgos = auditar_archivo(test_file)
            self.assertEqual(len(hallazgos), 1)
            h = hallazgos[0]
            self.assertIsNone(h["existe"])
            self.assertEqual(h["estado"], "indeterminado")
        finally:
            if test_file.exists():
                test_file.unlink()

    def test_confinamiento_y_traversal(self) -> None:
        fuera = REPO_ROOT.parent
        valido, msg, _ = validar_confinamiento_ruta(fuera)
        self.assertFalse(valido)
        self.assertIn("Acceso denegado", msg)

    def test_escritura_json_segura(self) -> None:
        prohibido = REPO_ROOT / "godot" / "guion" / "test.gd"
        valido, msg = validar_escritura_json_segura(prohibido)
        self.assertFalse(valido)
        self.assertIn("Política de escritura segura", msg)

        seguro = REPO_ROOT / "dist" / "reporte.json"
        valido_s, _ = validar_escritura_json_segura(seguro)
        self.assertTrue(valido_s)

    def test_ampliacion_llamadores_genericos(self) -> None:
        test_file = self.tmp_dir / "script_generico_test.gd"
        test_file.parent.mkdir(parents=True, exist_ok=True)
        try:
            test_file.write_text('func _ready():\n    iniciar_apertura_creditos()\n', encoding="utf-8")
            self.assertTrue(es_archivo_relacionado_intro(test_file))
        finally:
            if test_file.exists():
                test_file.unlink()


def ejecutar_self_test() -> int:
    """Ejecuta la suite de pruebas unitarias internas."""
    suite = unittest.TestLoader().loadTestsFromTestCase(PruebasSelfTestAuditorIntro)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    return 0 if result.wasSuccessful() else 1


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Auditor estático offline de referencias e incidencias de la secuencia de introducción (#395, #20261016)"
    )
    parser.add_argument(
        "--path",
        type=Path,
        default=Path("godot"),
        help="Ruta al archivo o directorio a auditar (default: godot)",
    )
    parser.add_argument(
        "--json-out",
        type=Path,
        default=None,
        help="Ruta de destino para exportar el informe JSON",
    )
    parser.add_argument(
        "--todos-los-archivos",
        action="store_true",
        help="Audita todos los archivos Godot sin filtrar exclusivamente por patrones de intro",
    )
    parser.add_argument(
        "--fail-on-missing",
        action="store_true",
        help="Devuelve código de salida 2 si se detecta alguna referencia inexistente",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Ejecuta la suite de pruebas unitarias integradas del auditor",
    )

    args = parser.parse_args(argv)

    if args.self_test:
        return ejecutar_self_test()

    # Si --path es relativa, interpretarla respecto a REPO_ROOT o CWD
    ruta_target = args.path
    if not ruta_target.is_absolute():
        if (REPO_ROOT / ruta_target).exists():
            ruta_target = REPO_ROOT / ruta_target

    valido, msg_err, target_abs = validar_confinamiento_ruta(ruta_target)
    if not valido or target_abs is None:
        print(f"Error: {msg_err}", file=sys.stderr)
        return 1

    if args.json_out:
        seguro, msg_seg = validar_escritura_json_segura(args.json_out)
        if not seguro:
            print(f"Error: {msg_seg}", file=sys.stderr)
            return 1

    reporte = auditar_ruta(target_abs, solo_intro=not args.todos_los_archivos)

    json_str = json.dumps(reporte, indent=2, ensure_ascii=False)
    print(json_str)

    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(json_str + "\n", encoding="utf-8")

    if args.fail_on_missing and reporte["total_referencias_inexistentes"] > 0:
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
