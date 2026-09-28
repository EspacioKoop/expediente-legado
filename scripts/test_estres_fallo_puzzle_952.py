from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"


class EstresFalloPuzzle952Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        texto = GATO.read_text(encoding="utf-8")
        cls.bloque = texto.split(
            "func _actualizar_objetivo_puzzle_onirico", 1
        )[1].split("func ", 1)[0]

    def test_fallo_aceptado_aplica_fallo_critico_despues_de_registrarlo(self):
        registrar = "SuenoObjetivos.fallar(estado, objetivo_id)"
        condicion = (
            "if fallo_registrado and "
            "resultado_estado == PuzzleOnirico.ESTADO_FALLADO:"
        )
        estres = 'Estres.aplicar(jornada, "fallo_critico")'

        self.assertIn("var fallo_registrado := " + registrar, self.bloque)
        self.assertIn(condicion, self.bloque)
        self.assertIn(estres, self.bloque)
        self.assertLess(self.bloque.index(registrar), self.bloque.index(condicion))
        self.assertLess(self.bloque.index(condicion), self.bloque.index(estres))

    def test_abandono_comparte_registro_pero_no_condicion_de_estres(self):
        self.assertIn(
            "resultado_estado == PuzzleOnirico.ESTADO_ABANDONADO",
            self.bloque,
        )
        condicion_estres = (
            "if fallo_registrado and "
            "resultado_estado == PuzzleOnirico.ESTADO_FALLADO:"
        )
        self.assertIn(condicion_estres, self.bloque)
        self.assertNotIn(
            "resultado_estado == PuzzleOnirico.ESTADO_ABANDONADO:\n"
            '\t\t\tEstres.aplicar(jornada, "fallo_critico")',
            self.bloque,
        )

    def test_fallo_terminal_no_se_puede_farmear(self):
        self.assertIn(
            "var fallo_registrado := SuenoObjetivos.fallar(estado, objetivo_id)",
            self.bloque,
        )
        self.assertIn(
            "if fallo_registrado and "
            "resultado_estado == PuzzleOnirico.ESTADO_FALLADO:",
            self.bloque,
        )
        self.assertIn("return fallo_registrado", self.bloque)


if __name__ == "__main__":
    unittest.main()
