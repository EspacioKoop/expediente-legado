import os
from pathlib import Path
import subprocess

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "ideologia_sueno_923.gd"
ESPACIO = ROOT / "godot" / "guion" / "sueno_espacio_simbolico.gd"
UTILERIA = ROOT / "godot" / "guion" / "sueno_utileria.gd"
REACTIVO = ROOT / "godot" / "guion" / "dia_sueno_reactivo_app.gd"
CIELO = ROOT / "godot" / "guion" / "dia_cielo_app.gd"
PRUEBA = ROOT / "godot" / "pruebas" / "pruebas_ideologia_sueno_923.gd"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_adaptador_no_mapea_ejes_a_estetica() -> None:
    codigo = fuente(MODELO)
    for eje in ("comunismo", "socialdemocrata", "centrista", "neoliberal"):
        assert f'"{eje}"' not in codigo
    assert "responsabilidad_colectiva" in codigo
    assert "garantias_procedimiento" in codigo
    assert "conciliacion" in codigo
    assert "CLAVE_EXPOSICION_IDEOLOGICA" in codigo


def test_eleccion_y_exposicion_tienen_semantica_distinta() -> None:
    codigo = fuente(MODELO)
    assert 'CANAL_ELECCION := "eleccion"' in codigo
    assert 'CANAL_EXPOSICION := "exposicion"' in codigo
    assert 'if canal == CANAL_ELECCION else ""' in codigo


def test_no_inventa_hechos_de_expediente() -> None:
    codigo = fuente(MODELO)
    for prohibido in (
        "pistas_descubiertas",
        "veredictos",
        "casos.json",
        "Contenido",
        "Progreso.caso_resuelto",
    ):
        assert prohibido not in codigo


def test_gramatica_estructural_sigue_sin_colisiones_ni_hud() -> None:
    codigo = fuente(ESPACIO)
    bloque = codigo.split("static func _aplicar_modificadores", 1)[1].split(
        "static func _motivo_soportado", 1
    )[0]
    assert 'String(modificador.get("canal", "")) != "eleccion"' in bloque
    assert "CollisionShape3D.new" not in bloque
    assert "Area3D.new" not in bloque
    assert "Control.new" not in bloque
    assert "ModificadorIdeologico" in bloque


def test_runtime_conecta_estructura_y_cielo_sin_fuente_paralela() -> None:
    reactivo = fuente(REACTIVO)
    cielo = fuente(CIELO)
    utileria = fuente(UTILERIA)
    assert 'preload("res://guion/ideologia_sueno_923.gd")' in reactivo
    assert "IDEOLOGIA_SUENO" in reactivo
    assert "modificadores_ideologicos" in reactivo
    assert "modificadores_simbolicos" in utileria
    assert "SuenoEspacioSimbolico.montar(mundo, creadas, modificadores_simbolicos)" in utileria
    assert 'preload("res://guion/ideologia_sueno_923.gd")' in cielo
    assert "resultado.append_array(" in cielo
    assert "IDEOLOGIA_SUENO.modificadores(" in cielo


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
