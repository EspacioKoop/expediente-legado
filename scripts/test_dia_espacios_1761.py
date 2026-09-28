from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
ESPACIOS = ROOT / "godot" / "guion" / "dia_espacios_app.gd"


class DiaEspacios1761Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.espacios = ESPACIOS.read_text(encoding="utf-8")

    def test_dia_conserva_hook_para_subclases(self):
        bloque = self.dia.split("func _espacio_de(fase: String) -> Dictionary:", 1)[1].split(
            "## #1182:", 1
        )[0]
        self.assertIn("DiaEspaciosApp.construir(", bloque)
        self.assertIn('Callable(self, "_opciones_sueno")', bloque)
        self.assertIn('Callable(self, "_registro_literario_para_sueno")', bloque)
        self.assertIn('Callable(self, "_plantilla_en")', bloque)
        self.assertIn('_rivales = resultado["rivales"]', bloque)

    def test_catalogo_y_sueno_viven_fuera_del_orquestador(self):
        for token in (
            "EspaciosCatalogo.de_fase",
            "SuenoContenido.fuentes",
            "SuenoContenido.repartir",
            "SuenoFormas.de",
            "SuenoLiteratura.aplicar",
        ):
            self.assertIn(token, self.espacios)
            self.assertNotIn(token, self.dia)

    def test_constructor_no_decide_transiciones(self):
        for token in (
            "Jornada.fichar_salida",
            "Jornada.dormir",
            "Jornada.despertar",
            "_guardar_o_avisar",
            "_entrar_en",
            "Partida.",
        ):
            self.assertNotIn(token, self.espacios)

    def test_dia_ya_esta_por_debajo_de_800_lineas(self):
        self.assertLess(len(self.dia.splitlines()), 800)


if __name__ == "__main__":
    unittest.main()
