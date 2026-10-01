import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "ecos_despertar.gd"
PRUEBA = "res://pruebas/pruebas_ecos_despertar_1775.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class EcosDespertar1775Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fuente = MODELO.read_text(encoding="utf-8")

    def test_material_vivido_sale_de_presentacion_runtime(self):
        self.assertIn("static func material_desde_noche(", self.fuente)
        self.assertIn("MutadoresSueno.HUMEDAD", self.fuente)
        self.assertIn("MutadoresSueno.DESFASE", self.fuente)
        self.assertIn("\"monitor\"", self.fuente)
        self.assertIn("\"televisor_casa\"", self.fuente)
        self.assertIn("\"silla\"", self.fuente)
        self.assertIn("\"archivador\"", self.fuente)
        self.assertIn("\"armario_hogar\"", self.fuente)
        self.assertNotIn("SuenoFormas", self.fuente)
        self.assertNotIn("ObjetosOniricos", self.fuente)

    def test_catalogo_y_seleccion_son_acotados(self):
        for tipo in ("humedad", "crt", "objeto_desplazado", "sonido_residual"):
            self.assertIn(f'"{tipo}"', self.fuente)
        self.assertIn('Azar.derivar(raiz, "sueno", [noche, 1775])', self.fuente)
        self.assertIn('"dia_vigilia": noche + 1', self.fuente)
        self.assertIn('"consumido": false', self.fuente)

    def test_no_es_otra_fuente_de_estado_global(self):
        for simbolo in (
            "Partida.",
            "Jornada.",
            "HuellasAmbientales",
            "Expediente",
            "dinero",
            "pista",
            "veredicto",
            "combate",
        ):
            self.assertNotIn(simbolo, self.fuente)

    def test_consumo_requiere_aceptacion_del_consumidor(self):
        bloque_oferta = self.fuente.split("static func oferta(", 1)[1].split(
            "static func aceptar(", 1
        )[0]
        self.assertNotIn('"consumido"] = true', bloque_oferta)
        bloque_aceptar = self.fuente.split("static func aceptar(", 1)[1].split(
            "static func descartar_al_avanzar(", 1
        )[0]
        self.assertIn('estado["consumido"] = true', bloque_aceptar)
        self.assertIn('eco_id != String(estado.get("id", ""))', bloque_aceptar)

    def test_reduccion_movimiento_no_cambia_logica(self):
        bloque = self.fuente.split("static func presentacion(", 1)[1]
        self.assertIn('"estilo": "corte" if reduccion_movimiento else "transicion"', bloque)
        self.assertNotIn('pendiente["consumido"] =', bloque)

    def test_contrato_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        if shutil.which(motor) is None:
            self.skipTest(f"{motor} no disponible en este entorno")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 25, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
