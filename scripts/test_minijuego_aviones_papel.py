from pathlib import Path
import re
import unittest

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "godot" / "guion" / "minijuego_aviones_papel.gd"
SCENE = ROOT / "godot" / "escenas" / "minijuego_aviones_papel.tscn"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class MinijuegoAvionesPapelTest(unittest.TestCase):
    def setUp(self):
        self.script = SCRIPT.read_text(encoding="utf-8")
        self.scene = SCENE.read_text(encoding="utf-8")
        self.textos = TEXTOS.read_text(encoding="utf-8")

    def test_escena_consumidora_del_nucleo(self):
        self.assertIn("AvionesPapel.nueva", self.script)
        self.assertIn("AvionesPapel.lanzar(", self.script)
        self.assertIn("AvionesPapel.lanzar_companero", self.script)
        self.assertIn("AvionesPapel.resultado", self.script)
        self.assertNotIn("const GRAVEDAD", self.script)
        self.assertNotIn("const LIMITE_FONDO", self.script)

    def test_superficie_jugable_con_controles_nativos(self):
        self.assertIn('type="OptionButton"', self.scene)
        self.assertEqual(self.scene.count('type="HSlider"'), 3)
        self.assertIn('text = "Lanzar"', self.scene)
        self.assertIn('text = "Abandonar"', self.scene)
        self.assertIn("Teclado/mando", self.scene)
        self.assertIn("modelo.grab_focus()", self.script)

    def test_pasillo_y_tres_modalidades(self):
        self.assertIn("const PISTA := Rect2", self.script)
        self.assertIn("OBJETIVO_PAPELERA", self.script)
        self.assertIn('const MODALIDADES := ["distancia", "precision", "zona"]', self.script)
        self.assertIn('const MODELOS := ["estable", "rapido", "impredecible"]', self.script)

    def test_texto_dinamico_sale_del_catalogo(self):
        claves = [
            "AVIONES_ESTADO_ABANDONADA",
            "AVIONES_ESTADO_FIN",
            "AVIONES_ESTADO_LANZAMIENTO",
            "AVIONES_ESTADO_VUELO",
            "AVIONES_LANZAR",
            "AVIONES_MARCADOR",
            "AVIONES_MODALIDAD_DISTANCIA",
            "AVIONES_MODALIDAD_PRECISION",
            "AVIONES_MODALIDAD_ZONA",
            "AVIONES_MODELO_ESTABLE",
            "AVIONES_MODELO_IMPREDECIBLE",
            "AVIONES_MODELO_RAPIDO",
            "AVIONES_NUEVA_RONDA",
        ]
        for clave in claves:
            self.assertIn(f"{clave},", self.textos)
            self.assertIn(f'"{clave}"', self.script)
        self.assertIn('tr("AVIONES_ESTADO_LANZAMIENTO")', self.script)
        self.assertNotIn('.text = "Tu turno', self.script)
        self.assertNotIn('.text = "Marcador', self.script)

    def test_prevision_reutiliza_el_simulador_sin_mutar_reglas(self):
        self.assertIn("func _vuelo_previo() -> Dictionary:", self.script)
        self.assertIn("AvionesPapel.simular(", self.script)
        self.assertIn("func _dibujar_prevision() -> void:", self.script)
        self.assertIn("direccion.value_changed.connect(_al_cambiar_configuracion)", self.script)
        self.assertIn("altura.value_changed.connect(_al_cambiar_configuracion)", self.script)
        self.assertIn("potencia.value_changed.connect(_al_cambiar_configuracion)", self.script)
        self.assertIn("modelo.item_selected.connect(_al_cambiar_configuracion)", self.script)
        bloque = self.script.split("func _vuelo_previo()", 1)[1].split(
            "\n\nfunc _dibujar_prevision", 1
        )[0]
        self.assertNotIn("AvionesPapel.lanzar(", bloque)
        self.assertNotIn('estado["', bloque)
        self.assertNotIn("Partida", bloque)

    def test_prevision_runtime_no_consume_lanzamientos(self):
        resultado = ejecutar_script("pruebas/pruebas_aviones_papel_preview_160.gd")
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 6, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)

    def test_abandono_no_persiste_recompensas(self):
        self.assertIn("AvionesPapel.abandonar", self.script)
        self.assertIn('tr("AVIONES_ESTADO_ABANDONADA")', self.script)
        self.assertIn("el ciclo diario no cambia", self.textos)
        self.assertNotIn("Partida", self.script)
        self.assertNotIn("sello", self.script.lower())
        self.assertNotIn("guardar", self.script.lower())


if __name__ == "__main__":
    unittest.main()
