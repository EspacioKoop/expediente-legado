from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
FISICA = ROOT / "godot" / "guion" / "ronda_cierre_3d.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_ronda_cierre_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
SMOKE = ROOT / "godot" / "pruebas" / "pruebas_ronda_cierre_3d.gd"


class RondaCierreFisica156Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fisica = FISICA.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")
        cls.smoke = SMOKE.read_text(encoding="utf-8")

    def test_reutiliza_interaccion_3d_sin_hud_flotante(self):
        self.assertIn("Interactuable3D.new()", self.fisica)
        self.assertIn("punto.activado.connect", self.fisica)
        self.assertNotIn("Label3D.new()", self.fisica)

    def test_cubre_todos_los_puntos_fisicos_base(self):
        for punto in (
            "recoger_a7",
            "apagar_lampara",
            "cerrar_puerta",
            "revisar_bandeja",
            "devolver_carpeta",
            "comprobar_tablon",
        ):
            self.assertIn(f'"{punto}"', self.fisica)

    def test_el_cunado_reutiliza_el_companero_real(self):
        self.assertIn("CompaneroInteractivo3D", self.fisica)
        self.assertIn("RondaCierre.PUNTO_CUNADO", self.fisica)
        self.assertIn("POS_CUNADO", self.fisica)

    def test_controlador_es_determinista_y_no_bloquea_salida(self):
        self.assertIn("static func ofrecida", self.controlador)
        self.assertIn("posmod(", self.controlador)
        self.assertIn("RondaCierre.abandonar(estado)", self.controlador)
        self.assertIn('fase != "archivo"', self.controlador)

    def test_concede_solo_el_sello_cosmetico_sin_tocar_balance(self):
        self.assertIn('SELLO_RECOMPENSA := "planta-en-orden"', self.controlador)
        self.assertIn("Sellos.registrar_sello", self.controlador)
        self.assertIn("Sellos.tiene_sello", self.controlador)
        bloque = (self.fisica + self.controlador).lower()
        for termino in (
            "gastar_accion",
            '["dinero"]',
            '["acciones"]',
            "pistas_descubiertas",
            "vidas",
        ):
            self.assertNotIn(termino, bloque)

    def test_montado_en_dia_y_con_smoke_de_recorrido_y_abandono(self):
        self.assertIn("dia_ronda_cierre_app.gd", self.escena)
        self.assertIn("RondaCierreController", self.escena)
        self.assertIn("_probar_recorrido_completo", self.smoke)
        self.assertIn("_probar_abandono_parcial", self.smoke)
        self.assertIn("_probar_sello_planta_en_orden", self.smoke)


if __name__ == "__main__":
    unittest.main()
