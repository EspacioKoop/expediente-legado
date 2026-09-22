from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
DIA_GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"
PARTIDA = ROOT / "godot" / "guion" / "partida.gd"
ECO = ROOT / "godot" / "guion" / "gato_eco_sueno.gd"


class GatoPersistencia787Test(unittest.TestCase):
    def test_objetivos_obligatorios_no_dependen_de_la_guia(self):
        dia = DIA_GATO.read_text(encoding="utf-8")
        entrada = dia.split("func _entrar_en(fase: String) -> void:", 1)[1].split(
            "func _reduccion_movimiento_gato", 1
        )[0]
        self.assertLess(entrada.index("_montar_objetivos_sueno()"), entrada.index("_montar_guia_sueno()"))

        guia = dia.split("func _montar_guia_sueno() -> void:", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("not GatoAyuda.guia_visible(gato)", guia)

        objetivos = dia.split("func _montar_objetivos_sueno() -> void:", 1)[1].split(
            "\nfunc _al_pisar_objetivo", 1
        )[0]
        self.assertNotIn("GatoAyuda", objetivos)
        self.assertNotIn("_gato_guia", objetivos)

    def test_persistencia_valida_la_memoria_del_gato(self):
        partida = PARTIDA.read_text(encoding="utf-8")
        eco = ECO.read_text(encoding="utf-8")
        self.assertIn("static func validar(gato: Dictionary)", eco)
        self.assertIn("GatoEcoSueno.validar(gato)", partida)
        self.assertIn('errores.append("gato.%s" % error)', partida)

    def test_contrato_ejecutable_en_godot(self):
        comprobar_contrato(
            self,
            "pruebas/pruebas_gato_persistencia_787.gd",
            "18 pasadas, 0 fallos",
        )


if __name__ == "__main__":
    unittest.main()
