from pathlib import Path
import re

SRC = Path("godot/guion/cinematicas_umbral.gd")
TEXT = SRC.read_text(encoding="utf-8")

IDS = [
    "umbral-expediente-imposible",
    "umbral-siga-fantasma",
    "umbral-llamada-sin-linea",
    "umbral-archivo-se-reordena",
    "umbral-regreso-oficina",
]

def test_catalogo_declara_cinco_ids_estables():
    for cinematic_id in IDS:
        assert cinematic_id in TEXT

def test_cada_cinematica_tiene_tres_planos_3d():
    funcs = [
        "_expediente_imposible",
        "_siga_fantasma",
        "_llamada_sin_linea",
        "_archivo_se_reordena",
        "_regreso_oficina",
    ]
    for i, name in enumerate(funcs):
        start = TEXT.index(f"static func {name}()")
        end = TEXT.find("\nstatic func ", start + 1)
        chunk = TEXT[start:] if end < 0 else TEXT[start:end]
        assert chunk.count('"tipo": "3d"') == 3, name
        assert chunk.count('"segundos":') >= 3, name
        assert chunk.count('"decorado": decorado') == 3, name

def test_api_valida_y_resuelve_con_motor_comun():
    assert "Cinematica.validar(declarados)" in TEXT
    assert "Cinematica.resolver(declarados, datos, vistas)" in TEXT

def test_no_hay_autoplay_ni_mutacion_de_partida():
    forbidden = ["change_scene", "Partida.", "get_tree().", "reproducir("]
    for token in forbidden:
        assert token not in TEXT
