from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
PERSIANA = ROOT / "godot" / "guion" / "persiana_atascada_3d.gd"
LINTERNA = ROOT / "godot" / "guion" / "linterna_casa_680.gd"


class UsosHerramientaRuntime1773Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.persiana = PERSIANA.read_text(encoding="utf-8")
        cls.linterna = LINTERNA.read_text(encoding="utf-8")

    def test_persiana_delega_en_resolver_comun(self):
        self.assertIn("UsosHerramienta.FORZAR", self.persiana)
        self.assertIn(
            "UsosHerramienta.resolver(_inventario, USO_REQUERIDO)",
            self.persiana,
        )
        self.assertNotIn("Inventario.visibles", self.persiana)
        self.assertNotIn("palanca_kkryy", self.persiana)

    def test_linterna_delega_en_resolver_comun(self):
        self.assertIn("UsosHerramienta.ILUMINAR", self.linterna)
        self.assertIn(
            "UsosHerramienta.resolver(inventario, USO_REQUERIDO)",
            self.linterna,
        )
        self.assertNotIn("Inventario.CARRIED", self.linterna)
        self.assertNotIn("linterna_kkryy", self.linterna)

    def test_ambas_interacciones_siguen_sin_consumo_implicito(self):
        self.assertNotIn("Inventario.retirar", self.persiana)
        self.assertNotIn("Inventario.retirar", self.linterna)
        self.assertNotIn("Inventario.guardar_en_casa", self.persiana)
        self.assertNotIn("Inventario.guardar_en_casa", self.linterna)

    def test_no_se_crea_estado_paralelo(self):
        for fuente in (self.persiana, self.linterna):
            self.assertNotIn("Partida.new", fuente)
            self.assertNotIn("Jornada.nueva", fuente)
            self.assertNotIn("FileAccess", fuente)
            self.assertNotIn("user://", fuente)


if __name__ == "__main__":
    unittest.main()
