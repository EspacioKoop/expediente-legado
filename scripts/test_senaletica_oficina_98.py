"""Señalética propia del archivo (#1468): binarios, procedencia y montaje."""
from pathlib import Path
import hashlib
import json
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import generar_senaletica_oficina_98 as generador  # noqa: E402

ASSETS = ROOT / "godot" / "assets"
RUNTIME = ROOT / "godot" / "guion" / "senaletica_oficina_98.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_oficina_utileria_app.gd"
ATRIBUTOS = ROOT / ".gitattributes"
CARPETA = "texturas/senaletica_oficina_98"


class SenaleticaOficina98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runtime = RUNTIME.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        registro = json.loads((ASSETS / "procedencia.json").read_text(encoding="utf-8"))
        cls.fichas = {f["ruta"]: f for f in registro["assets"]}

    def test_binarios_versionados_se_regeneran_pixel_a_pixel(self):
        # Se compara el contenido decodificado y no los bytes: otra versión de
        # zlib puede comprimir distinto la misma imagen.
        for nombre in generador.LAMINAS:
            with self.subTest(nombre=nombre):
                versionado = generador.leer_png((ASSETS / CARPETA / nombre).read_bytes())
                self.assertEqual(versionado, generador.renderizar(nombre))

    def test_procedencia_hash_y_tamano(self):
        for nombre in generador.LAMINAS:
            rel = f"{CARPETA}/{nombre}"
            with self.subTest(ruta=rel):
                ficha = self.fichas[rel]
                contenido = (ASSETS / rel).read_bytes()
                self.assertEqual(hashlib.sha256(contenido).hexdigest(), ficha["sha256"])
                self.assertEqual(ficha["origen"], "generado_por_script")
                self.assertIn("generar_senaletica_oficina_98.py", ficha["autor"])
                self.assertLess(len(contenido), 10 * 1024)

    def test_no_son_punteros_lfs(self):
        # Sin objeto LFS subido, un puntero rompería el checkout de todos.
        self.assertRegex(
            ATRIBUTOS.read_text(encoding="utf-8"),
            r"godot/assets/texturas/senaletica_oficina_98/\*\.png\s+-filter\s+-diff\s+-merge\s+-text",
        )
        for nombre in generador.LAMINAS:
            cabecera = (ASSETS / CARPETA / nombre).read_bytes()[:8]
            self.assertEqual(cabecera, b"\x89PNG\r\n\x1a\n", nombre)

    def test_calendario_no_afirma_una_fecha(self):
        fuente = Path(generador.__file__).read_text(encoding="utf-8")
        cuerpo = fuente.split("def calendario", 1)[1].split("\nLAMINAS", 1)[0]
        self.assertNotIn("texto", cuerpo)
        self.assertNotRegex(cuerpo, r"\b(19|20)\d\d\b")

    def test_runtime_monta_las_tres_laminas_solo_en_archivo(self):
        for nombre in generador.LAMINAS:
            self.assertIn(f'"{nombre}"', self.runtime)
        self.assertRegex(self.controlador, r"SenaleticaOficina98\.montar\(\s*mundo\s*\)")
        self.assertIn('String(dia.jornada.get("fase", "")) == "archivo"', self.controlador)

    def test_lamina_plana_sin_fisica_e_idempotente(self):
        self.assertIn("mundo.has_node(NOMBRE_CAPA)", self.runtime)
        self.assertIn("QuadMesh.new()", self.runtime)
        self.assertIn("TRANSPARENCY_ALPHA_SCISSOR", self.runtime)
        self.assertNotRegex(self.runtime, r"BILLBOARD_|Sprite3D\.new")
        for termino in ("Area3D", "CollisionShape3D", "Interactuable3D", "Partida", "guardar("):
            self.assertNotIn(termino, self.runtime)

    def test_ubicaciones_no_pisan_posteres_ni_cuadros(self):
        ocupados = []
        for ruta in ("posters_oficina.gd", "cuadros_oficina.gd"):
            texto = (ROOT / "godot" / "guion" / ruta).read_text(encoding="utf-8")
            ocupados += [
                tuple(float(v) for v in m)
                for m in re.findall(r"Vector3\(([-\d.]+),\s*([-\d.]+),\s*([-\d.]+)\)", texto)
            ]
        propias = [
            tuple(float(v) for v in m)
            for m in re.findall(r"Vector3\(([-\d.]+),\s*([-\d.]+),\s*([-\d.]+)\)", self.runtime)
        ]
        self.assertEqual(len(propias), 3)
        for x, y, z in propias:
            for ox, oy, oz in ocupados:
                # Misma pared (una coordenada horizontal casi igual): exigir
                # separación suficiente en la otra.
                if abs(z - oz) < 0.1:
                    self.assertGreater(abs(x - ox), 0.9, (x, y, z, ox, oy, oz))
                if abs(x - ox) < 0.1:
                    self.assertGreater(abs(z - oz), 0.9, (x, y, z, ox, oy, oz))


if __name__ == "__main__":
    unittest.main()
