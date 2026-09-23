import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ESTRES = ROOT / "godot" / "guion" / "estres.gd"
MARCADORES = ROOT / "godot" / "guion" / "dia_marcadores_mundo_app.gd"
VISOR = ROOT / "godot" / "guion" / "visor_expediente.gd"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
SMOKE = "pruebas/issue_952_smoke.gd"


class Estres952Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.estres = ESTRES.read_text(encoding="utf-8")
        cls.marcadores = MARCADORES.read_text(encoding="utf-8")
        cls.visor = VISOR.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_estado_invisible_y_acotado_vive_en_jornada(self):
        self.assertIn('const CAMPO_JORNADA := "estres_dinamico"', self.estres)
        self.assertIn("clampf(anterior + delta, 0.0, VALOR_MAXIMO)", self.estres)
        self.assertIn("static func nivel(jornada: Dictionary) -> float:", self.estres)
        self.assertNotIn("Partida", self.estres)
        self.assertNotIn("ProgressBar", self.estres)
        self.assertNotIn("TextureProgressBar", self.estres)

    def test_catalogo_cubre_tension_y_recuperacion_sin_bloqueos(self):
        for evento in (
            "documento_sensible",
            "oscuridad",
            "fallo_critico",
            "sonido_inquietante",
            "zona_segura",
            "autocuidado",
            "resolucion",
        ):
            self.assertIn(f'"{evento}"', self.estres)
        for termino_prohibido in ("game_over", "bloquear", "vida -=", "acciones -="):
            self.assertNotIn(termino_prohibido, self.estres.lower())

    def test_marcadores_consumen_la_fuente_canonica_sin_duplicarla(self):
        self.assertIn("Estres.nivel(_host.jornada)", self.marcadores)
        self.assertIn("_estres_presentacion", self.marcadores)
        self.assertIn(
            "visual.configurar(datos, en_sueno, _estres_presentacion)",
            self.marcadores,
        )
        self.assertNotIn('jornada["estres_dinamico"]', self.marcadores)

    def test_visor_convierte_lectura_confidencial_en_productor_real(self):
        bloque = self.visor.split("func _al_elegir_documento", 1)[1].split(
            "func _mostrar_registro", 1
        )[0]
        evento = 'Estres.aplicar(jornada, "documento_sensible")'
        self.assertIn('if bool(caso.get("confidencial", false)):', bloque)
        self.assertIn(evento, bloque)
        self.assertLess(bloque.index("Jornada.gastar_lectura"), bloque.index(evento))
        self.assertLess(bloque.index("Jornada.anotar_lectura"), bloque.index(evento))
        self.assertNotIn('jornada["estres_dinamico"]', bloque)

    def test_ambiente_consume_el_nivel_canonico(self):
        self.assertIn('"estres": Estres.nivel(jornada)', self.dia)
        self.assertNotIn('jornada["estres_dinamico"]', self.dia)

    def test_smoke_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                SMOKE,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("issue_952:", resultado.stdout)
        self.assertIn("0 fallos", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
