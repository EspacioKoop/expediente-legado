import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "godot" / "guion" / "menu_global.gd"
VERIFICACION = ROOT / "godot" / "guion" / "verificacion_falsa.gd"
DATOS = ROOT / "godot" / "datos" / "verificacion_falsa_textos.json"
PRUEBA_GODOT = "pruebas/pruebas_tarot_diablo_1029.gd"
RESUMEN = re.compile(r"tarot_diablo_1029: (\d+) pasadas, 0 fallos")


def bloque(fuente: str, inicio: str, fin: str) -> str:
    desde = fuente.index(inicio)
    hasta = fuente.index(fin, desde)
    return fuente[desde:hasta]


class TarotDiablo1029Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.menu = MENU.read_text(encoding="utf-8")
        cls.verificacion = VERIFICACION.read_text(encoding="utf-8")
        cls.datos = DATOS.read_text(encoding="utf-8")

    def test_conserva_probabilidad_del_legado_sin_convertir_menu_en_trigger(self) -> None:
        self.assertIn("const PROBABILIDAD := 0.3", self.verificacion)
        abrir = bloque(self.menu, "func _abrir()", "func _cerrar()")
        self.assertIn("_quizas_mostrar_verificacion()", abrir)
        self.assertNotIn('"el-diablo"', abrir)
        self.assertNotIn("desbloquear_carta_en_estado", abrir)

    def test_la_aparicion_es_el_evento_real_y_usa_frontera_comun(self) -> None:
        self.assertIn(
            'Prometeo.desbloquear_carta_en_estado(estado, "el-diablo")',
            self.verificacion,
        )
        evento = bloque(
            self.menu,
            "func _quizas_mostrar_verificacion()",
            "func _tiradas_verificacion(",
        )
        self.assertIn(
            'VerificacionFalsa.debe_mostrar(int(tiradas["aparicion"]))',
            evento,
        )
        mostrar = evento.index('_verificacion.mostrar(int(tiradas["pregunta"]))')
        registrar = evento.index("VerificacionFalsa.registrar(partida_actual.estado)")
        mundo = evento.index("Prometeo.sincronizar_tarot_mundo")
        guardar = evento.index("partida_actual.guardar()")
        self.assertLess(mostrar, registrar)
        self.assertLess(registrar, mundo)
        self.assertLess(mundo, guardar)

    def test_sorteo_usa_semilla_y_estado_reproducible(self) -> None:
        tiradas = bloque(
            self.menu,
            "func _tiradas_verificacion(",
            "func _al_cerrar_verificacion()",
        )
        self.assertIn('estado.get("semilla", 0)', tiradas)
        self.assertIn('jornada.get("vuelta", 1)', tiradas)
        self.assertIn('jornada.get("dia", 1)', tiradas)
        self.assertIn('jornada.get("acciones", 0)', tiradas)
        self.assertIn('jornada.get("fase", "")', tiradas)
        self.assertIn('Azar.derivar_texto(raiz, "dia"', tiradas)
        self.assertIn('Azar.derivar_texto(raiz, "presentacion"', tiradas)
        self.assertNotIn("randf(", tiradas)
        self.assertNotIn("randi", tiradas)
        self.assertNotIn("randomize", tiradas)
        self.assertNotIn("randi_range", self.verificacion)

    def test_cancelar_cierra_verificacion_antes_que_menu(self) -> None:
        entrada = bloque(self.menu, "func _unhandled_input(", "func _puede_abrir()")
        self.assertIn("_verificacion.visible", entrada)
        self.assertIn("_verificacion.ocultar()", entrada)
        self.assertIn("get_viewport().set_input_as_handled()", entrada)

    def test_copy_viene_de_recurso_aislado(self) -> None:
        for texto in (
            "Verificación interna",
            "Marca la casilla que no pertenece a este universo.",
            "Soy una persona",
            "No soy un robot",
            "He leído el manual del miedo",
        ):
            self.assertIn(texto, self.datos)
            self.assertNotIn(texto, self.verificacion)
        self.assertIn(
            'const RUTA_TEXTOS := "res://datos/verificacion_falsa_textos.json"',
            self.verificacion,
        )

    def test_contrato_ejecutable_en_godot(self) -> None:
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIsNotNone(RESUMEN.search(resultado.stdout), resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
