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
        fallo = "resultado_estado == PuzzleOnirico.ESTADO_FALLADO"
        registrar = "SuenoObjetivos.fallar(estado, objetivo_id)"
        estres = 'Estres.aplicar(jornada, "fallo_critico")'

        self.assertIn(fallo, self.bloque)
        self.assertIn("if not " + registrar + ":", self.bloque)
        self.assertIn(estres, self.bloque)
        self.assertLess(self.bloque.index(fallo), self.bloque.index(registrar))
        self.assertLess(self.bloque.index(registrar), self.bloque.index(estres))

    def test_abandono_registra_objetivo_sin_aplicar_estres(self):
        abandono = self.bloque.split(
            "if resultado_estado == PuzzleOnirico.ESTADO_ABANDONADO:", 1
        )[1]
        self.assertIn(
            "return SuenoObjetivos.fallar(estado, objetivo_id)",
            abandono,
        )
        self.assertNotIn('Estres.aplicar(jornada, "fallo_critico")', abandono)

    def test_fallo_no_se_puede_farmear_si_objetivo_ya_es_terminal(self):
        fallo = self.bloque.split(
            "if resultado_estado == PuzzleOnirico.ESTADO_FALLADO:", 1
        )[1].split(
            "if resultado_estado == PuzzleOnirico.ESTADO_ABANDONADO:", 1
        )[0]
        self.assertIn("if not SuenoObjetivos.fallar(estado, objetivo_id):", fallo)
        self.assertIn("return false", fallo)
        self.assertLess(
            fallo.index("return false"),
            fallo.index('Estres.aplicar(jornada, "fallo_critico")'),
        )


if __name__ == "__main__":
    unittest.main()
