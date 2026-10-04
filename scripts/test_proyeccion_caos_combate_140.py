from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
VISOR = ROOT / "godot/guion/visor_proyeccion_app.gd"
CONTRATO = ROOT / "godot/guion/proyeccion_caos_combate_140.gd"
TEXTOS = ROOT / "godot/datos/textos.csv"


class ProyeccionCaosCombate140Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.visor = VISOR.read_text(encoding="utf-8")
        cls.contrato = CONTRATO.read_text(encoding="utf-8")
        cls.textos = TEXTOS.read_text(encoding="utf-8")

    def test_regresion_pura_en_godot(self):
        salida = comprobar_contrato(
            self,
            "pruebas/pruebas_proyeccion_caos_combate_140.gd",
            "0 fallos",
        )
        self.assertIn("pasadas", salida)

    def test_firma_sigue_guardandose_antes_de_proyeccion_y_pelea(self):
        guardar = self.visor.index("if not _guardar_o_avisar():")
        proyectar = self.visor.index("_reproducir_proyeccion(resultado, estado)", guardar)
        abrir = self.visor.index("_abrir_combate_publico_caos(resultado)")
        self.assertLess(guardar, proyectar)
        self.assertLess(proyectar, abrir)

    def test_solo_caos_inserta_juicio_comun(self):
        self.assertIn("ProyeccionCaosCombate140.debe_abrir(resultado)", self.visor)
        self.assertIn("var combate := JuicioCombate3D.new()", self.visor)
        self.assertIn("ProyeccionCaosCombate140.BONO_COMBATE_BREVE", self.visor)
        self.assertIn('evento.is_action_pressed("cancelar")', self.visor)
        self.assertIn('evento.is_action_pressed("ui_cancel")', self.visor)
        self.assertIn("_combate_publico_caos.abandonar()", self.visor)

    def test_ganar_perder_o_abandonar_convergen_al_mismo_sello(self):
        inicio = self.visor.index("func _al_terminar_combate_publico_caos(")
        fin = self.visor.index("func _unhandled_input", inicio)
        callback = self.visor[inicio:fin]
        self.assertIn("_gano: bool", callback)
        self.assertIn("_reproducir_sello(resultado)", callback)
        self.assertNotIn("if _gano", callback)
        self.assertNotIn("if not _gano", callback)

    def test_incidente_no_reabre_ni_muta_reglas_de_acusacion(self):
        for prohibido in (
            "Acusacion.",
            "Jornada.",
            "Partida.",
            "registrar_sello(",
            "resolver_duelo(",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, self.contrato)
        self.assertNotIn("_guardar_o_avisar()", self.visor[self.visor.index("func _al_terminar_combate_publico_caos("):])

    def test_copy_del_publico_es_traducible(self):
        self.assertIn('"nombre": CLAVE_NOMBRE_PUBLICO', self.contrato)
        self.assertIn("PROYECCION_CAOS_PUBLICO,Público descontrolado", self.textos)


if __name__ == "__main__":
    unittest.main()
