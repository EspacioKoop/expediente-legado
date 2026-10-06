from pathlib import Path
import re

TEXT = Path("godot/guion/cinematicas_psicodelicas.gd").read_text(encoding="utf-8")

IDS = [
    "psico-expediente-suena",
    "psico-comite-imposible",
    "psico-archivo-bajo-ciudad",
    "psico-jardin-colgante-siga",
    "psico-identidades-superpuestas",
]

FUNCS = [
    "_expediente_suena",
    "_comite_imposible",
    "_archivo_bajo_la_ciudad",
    "_jardin_colgante_siga",
    "_identidades_superpuestas",
]


def _chunk(name: str) -> str:
    start = TEXT.index(f"static func {name}()")
    end = TEXT.find("\n\nstatic func ", start + 1)
    return TEXT[start:] if end < 0 else TEXT[start:end]


def test_ids_estables_y_motor_comun():
    for cinematic_id in IDS:
        assert cinematic_id in TEXT
    assert "Cinematica.validar(declarados)" in TEXT
    assert "Cinematica.resolver(declarados, datos, vistas)" in TEXT


def test_todas_son_largas_y_multiescenario():
    for name in FUNCS:
        chunk = _chunk(name)
        assert chunk.count("_plano(") >= 8, name
        escenarios = sum(chunk.count(token) for token in (
            "_oficina(", "_archivo(", "_escuela(", "_desierto(", "_castillo(", "_vacio("
        ))
        assert escenarios >= 4, name


def test_figuras_humanas_forman_parte_del_montaje():
    assert "static func _figura(" in TEXT
    for name in FUNCS:
        chunk = _chunk(name)
        assert "_figura(" in chunk or "figura" in chunk or "operador" in chunk


def test_no_hay_autoplay_ni_mutacion_de_partida():
    for token in ("change_scene", "Partida.", "get_tree().", ".reproducir("):
        assert token not in TEXT


def test_nuevas_piezas_extienden_montaje_y_personajes():
    assert "static func _jardin_colgante(" in TEXT
    assert "static func _faro(" in TEXT
    assert "CAMBIOS GUARDADOS" in TEXT
    assert "IDENTIDAD PROVISIONAL" in TEXT
