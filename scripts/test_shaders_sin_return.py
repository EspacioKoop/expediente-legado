"""Ningún shader sale con `return` de fragment(), vertex() o light().

Godot 4.7 lo rechaza al compilar y el material se queda sin dibujar. La suite
corre sin ventana y ahí los shaders de canvas no se compilan, así que el fallo
solo se veía jugando: la Portátil Color 98 salió con la pantalla vacía (#768).
"""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"
PROCESADORES = re.compile(r"\bvoid\s+(fragment|vertex|light)\s*\(\s*\)\s*\{")


def _cuerpo(codigo: str, apertura: int) -> str:
    profundidad = 0
    for indice in range(apertura, len(codigo)):
        if codigo[indice] == "{":
            profundidad += 1
        elif codigo[indice] == "}":
            profundidad -= 1
            if profundidad == 0:
                return codigo[apertura : indice + 1]
    return codigo[apertura:]


def _fuentes_shader():
    for ruta in sorted(GODOT.rglob("*.gdshader")):
        if ".godot" not in ruta.parts and "native" not in ruta.parts:
            yield ruta, ruta.read_text(encoding="utf-8")
    for ruta in sorted((GODOT / "guion").glob("*.gd")):
        texto = ruta.read_text(encoding="utf-8")
        if "shader_type" in texto:
            yield ruta, texto


class ShadersSinReturnTest(unittest.TestCase):
    def test_ningun_procesador_usa_return(self):
        hallazgos = []
        for ruta, codigo in _fuentes_shader():
            for coincidencia in PROCESADORES.finditer(codigo):
                cuerpo = _cuerpo(codigo, coincidencia.end() - 1)
                if re.search(r"\breturn\b", cuerpo):
                    hallazgos.append(f"{ruta.relative_to(ROOT)}: {coincidencia.group(1)}()")
        self.assertEqual(hallazgos, [])

    def test_detecta_el_caso_de_la_portatil(self):
        codigo = "void fragment() {\n if (x) {\n COLOR = c;\n return;\n }\n}\n"
        coincidencia = PROCESADORES.search(codigo)
        self.assertIsNotNone(coincidencia)
        self.assertRegex(_cuerpo(codigo, coincidencia.end() - 1), r"\breturn\b")


if __name__ == "__main__":
    unittest.main()
