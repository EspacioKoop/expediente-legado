import os
from pathlib import Path
import subprocess

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
PROMETEO = ROOT / "godot" / "guion" / "prometeo.gd"
PARTIDA = ROOT / "godot" / "guion" / "partida.gd"
FINAL = ROOT / "godot" / "guion" / "final_politico.gd"
PRUEBA = ROOT / "godot" / "pruebas" / "pruebas_trayectoria_ideologica_925.gd"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_reset_archiva_antes_de_borrar_estado_activo() -> None:
    codigo = fuente(PROMETEO)
    bloque = codigo.split(
        "static func reiniciar_vuelta(estado: Dictionary, vida_maxima: int) -> Dictionary:",
        1,
    )[1].split("static func _entero_no_negativo", 1)[0]
    sello = 'archivar_trayectoria_ideologica(estado, "reinicio_vuelta")'
    assert sello in bloque
    assert 'estado["historias_cartas"] = {}' in bloque
    assert "estado[CLAVE_ELECCIONES_IDEOLOGICAS] = []" in bloque
    assert bloque.index(sello) < bloque.index('estado["historias_cartas"] = {}')
    assert bloque.index(sello) < bloque.index(
        "estado[CLAVE_ELECCIONES_IDEOLOGICAS] = []"
    )


def test_partida_persiste_y_valida_historial_sin_version_global_nueva() -> None:
    codigo = fuente(PARTIDA)
    assert "Prometeo.CLAVE_HISTORIAL_IDEOLOGICO: []" in codigo
    assert "Prometeo.validar_historial_trayectorias_ideologicas" in codigo
    assert "const VERSION := 1" in codigo


def test_final_archiva_la_ultima_vida_de_forma_idempotente() -> None:
    codigo = fuente(FINAL)
    bloque = codigo.split(
        "static func confirmar_cierre(estado: Dictionary) -> Array:",
        1,
    )[1].split("static func _patron", 1)[0]
    assert 'Prometeo.archivar_trayectoria_ideologica(estado, "final_narrativo")' in bloque
    assert 'estado["final_politico_mostrado"] = true' in bloque


def test_snapshot_no_mezcla_exposicion_ni_lecturas_sociales() -> None:
    codigo = fuente(PROMETEO)
    bloque = codigo.split(
        "static func resumen_trayectoria_ideologica(estado: Dictionary) -> Dictionary:",
        1,
    )[1].split("static func archivar_trayectoria_ideologica", 1)[0]
    assert "elecciones_ideologicas(estado)" in bloque
    assert "CLAVE_EXPOSICION_IDEOLOGICA" not in bloque
    assert "CLAVE_LECTURAS_SOCIALES" not in bloque


def test_regresion_ejecutable_en_godot() -> None:
    motor = os.environ.get("GODOT_BIN", "godot4")
    importar_proyecto()
    resultado = subprocess.run(
        [
            motor,
            "--headless",
            "--path",
            str(ROOT / "godot"),
            "--script",
            str(PRUEBA.relative_to(ROOT / "godot")),
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=30,
        check=False,
    )
    assert resultado.returncode == 0, resultado.stdout
    assert "0 fallos" in resultado.stdout
    assert "Parse Error:" not in resultado.stdout
    assert "SCRIPT ERROR:" not in resultado.stdout
