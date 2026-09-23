from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
DIA_GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"
GATO = ROOT / "godot" / "guion" / "gato.gd"


class GatoAnclaOnirica787Test(unittest.TestCase):
    def test_guia_activa_el_ancla_estable(self):
        dia = DIA_GATO.read_text(encoding="utf-8")
        bloque = dia.split("func _montar_guia_sueno() -> void:", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("_gato_guia.anclar_presentacion_global()", bloque)

    def test_orientacion_lee_el_mundo_deformado_en_global(self):
        dia = DIA_GATO.read_text(encoding="utf-8")
        bloque = dia.split("func _orientar_gato_guia() -> void:", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("_mundo.to_global(_entrada_guia)", bloque)
        self.assertIn("_mundo.to_global(_salida_guia)", bloque)

    def test_gato_expone_un_contrato_de_presentacion_sin_estado_jugable(self):
        gato = GATO.read_text(encoding="utf-8")
        bloque = gato.split("func anclar_presentacion_global() -> void:", 1)[1].split("\n\n", 1)[0]
        self.assertIn("top_level = true", bloque)
        self.assertIn("Transform3D(Basis.IDENTITY, origen)", bloque)
        for prohibido in ("jornada", "hambre", "GatoEcoSueno", "SuenoObjetivos"):
            self.assertNotIn(prohibido, bloque)

    def test_contrato_ejecutable_en_godot(self):
        comprobar_contrato(
            self,
            "pruebas/pruebas_gato_ancla_onirica_787.gd",
            "8 pasadas, 0 fallos",
        )


if __name__ == "__main__":
    unittest.main()
