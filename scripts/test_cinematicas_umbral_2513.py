import unittest
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


class TestCinematicasUmbral(unittest.TestCase):
    def test_catalogo_declara_cinco_ids_estables(self):
        for cinematic_id in IDS:
            assert cinematic_id in TEXT

    def test_cada_cinematica_tiene_tres_planos_3d(self):
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
            # Cada escena crea tres planos con _plano(), que añade sus
            # campos obligatorios de tipo, segundos y decorado.
            assert chunk.count("_plano(") == 3, name

        # El helper centraliza los campos comunes de todos los planos.
        start = TEXT.index("static func _plano(")
        end = TEXT.index("static func _expediente_imposible()")
        helper = TEXT[start:end]
        assert '"tipo": "3d"' in helper
        assert '"segundos": segundos' in helper
        assert '"decorado": decorado' in helper

    def test_api_valida_y_resuelve_con_motor_comun(self):
        assert "Cinematica.validar(declarados)" in TEXT
        assert "Cinematica.resolver(declarados, datos, vistas)" in TEXT

    def test_no_hay_autoplay_ni_mutacion_de_partida(self):
        forbidden = ["change_scene", "Partida.", "get_tree().", "reproducir("]
        for token in forbidden:
            assert token not in TEXT
