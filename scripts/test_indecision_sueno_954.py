from pathlib import Path
import re
import unittest

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
HISTORIAS = ROOT / "godot/guion/historias.gd"
JORNADA = ROOT / "godot/guion/jornada.gd"
SELECCION = ROOT / "godot/guion/seleccion_nocturna.gd"
SUENO = ROOT / "godot/guion/sueno.gd"
PRUEBA = "pruebas/pruebas_indecision_sueno_954.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class IndecisionSueno954Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.historias = HISTORIAS.read_text(encoding="utf-8")
        cls.jornada = JORNADA.read_text(encoding="utf-8")
        cls.seleccion = SELECCION.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")

    def test_presion_se_proyecta_como_snapshot_de_jornada(self):
        self.assertIn('const CLAVE_PRESION_ONIRICA := "presion_indecision_onirica"', self.historias)
        self.assertIn("_sincronizar_presion_onirica(estado)", self.historias)
        self.assertIn('"presion_indecision_onirica": 0', self.jornada)

        bloque = self.historias.split("func _sincronizar_presion_onirica", 1)[1].split(
            "\n\n## Diario", 1
        )[0]
        self.assertIn("presion_indecision(estado)", bloque)
        self.assertNotIn("pistas_descubiertas", bloque)
        self.assertNotIn('["dinero"]', bloque)
        self.assertNotIn('["acciones"]', bloque)

    def test_seleccion_solo_inyecta_rumiacion_sin_reescribir_cantidad(self):
        self.assertIn('opciones["rumiacion_indecision"]', self.seleccion)
        bloque = self.seleccion.split("func opciones_sueno", 1)[1]
        self.assertNotIn('opciones["cantidad"] =', bloque)
        self.assertNotIn('opciones["priorizar_vistas"] =', bloque)

    def test_sueno_adelanta_como_maximo_una_sala_conocida(self):
        self.assertIn("func _ordenar_por_rumiacion(", self.sueno)
        self.assertIn("return [nuevas[0], recurrente] + nuevas.slice(1) + resto_vistas", self.sueno)
        self.assertIn("return [recurrente] + nuevas + resto_vistas", self.sueno)
        self.assertIn("if priorizar_vistas:", self.sueno)

    def test_integracion_runtime(self):
        resultado = ejecutar_script(PRUEBA)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
