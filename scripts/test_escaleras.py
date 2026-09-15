from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CAPA = RAIZ / "godot" / "guion" / "dia_ascensor_app.gd"
APP = RAIZ / "godot" / "guion" / "escaleras_3d_app.gd"
ESCENA = RAIZ / "godot" / "escenas" / "escaleras_3d.tscn"
ARTE = RAIZ / "godot" / "arte" / "escaleras_135" / "escaleras_135_arte.gd"
ARTE_ESCENA = RAIZ / "godot" / "arte" / "escaleras_135" / "escaleras_135_arte.tscn"


class EscalerasTest(unittest.TestCase):
    def setUp(self):
        self.capa = CAPA.read_text(encoding="utf-8")
        self.app = APP.read_text(encoding="utf-8")
        self.escena = ESCENA.read_text(encoding="utf-8")
        self.arte = ARTE.read_text(encoding="utf-8")
        self.arte_escena = ARTE_ESCENA.read_text(encoding="utf-8")

    def test_la_salida_ofrece_dos_rutas_sin_duplicar_el_fichaje(self):
        self.assertIn('preload("res://escenas/ascensor_3d.tscn")', self.capa)
        self.assertIn('preload("res://escenas/escaleras_3d.tscn")', self.capa)
        self.assertIn('_selector_ruta.ok_button_text = "Ascensor"', self.capa)
        self.assertIn('_selector_ruta.add_button("Escaleras"', self.capa)
        self.assertEqual(self.capa.count("Jornada.fichar_salida(jornada)"), 1)

    def test_estado_y_guardado_se_resuelven_antes_del_selector(self):
        fichar = self.capa.index("Jornada.fichar_salida(jornada)")
        destino = self.capa.index('_entrar_en("trayecto")', fichar)
        guardar = self.capa.index('if not _guardar_o_avisar(""):', destino)
        selector = self.capa.index("_mostrar_selector_ruta()", guardar)
        self.assertLess(fichar, destino)
        self.assertLess(destino, guardar)
        self.assertLess(guardar, selector)

    def test_escaleras_son_ruta_jugable_de_cuatro_tramos(self):
        self.assertIn('path="res://guion/escaleras_3d_app.gd"', self.escena)
        self.assertIn('signal terminada', self.app)
        self.assertIn('Input.get_axis("mover_atras", "mover_adelante")', self.app)
        self.assertIn("const ESCALONES_POR_TRAMO := 12", self.app)
        self.assertIn("4 -> 3 -> 2 -> 1 -> portal", self.app)
        self.assertIn("terminada.emit()", self.app)

    def test_ruta_no_tiene_autoridad_sobre_la_jornada(self):
        for llamada in (
            "Jornada.fichar_salida(",
            "Jornada.dormir(",
            "Jornada.despertar(",
            "Jornada.perder_vida(",
            '_entrar_en("',
            "partida.guardar",
        ):
            self.assertNotIn(llamada, self.app)
            self.assertNotIn(llamada, self.arte)

    def test_ascensor_y_escaleras_restauran_el_mismo_dia(self):
        self.assertIn("_ascensor.terminada.connect(_cerrar_ascensor)", self.capa)
        self.assertIn("_escaleras.terminada.connect(_cerrar_escaleras)", self.capa)
        self.assertIn("_restaurar_dia_tras_transito()", self.capa)
        self.assertGreaterEqual(self.capa.count("_restaurar_dia_tras_transito()"), 3)

    def test_vestuario_fotorealista_es_visual_y_no_bloquea_la_ruta(self):
        self.assertIn(
            'preload("res://arte/escaleras_135/escaleras_135_arte.tscn")',
            self.app,
        )
        self.assertIn("VestuarioEscaleras135", self.app)
        self.assertIn('path="res://arte/escaleras_135/escaleras_135_arte.gd"', self.arte_escena)
        self.assertIn("MAT_PARED", self.arte)
        self.assertIn("MAT_TERRAZO", self.arte)
        self.assertIn("MAT_METAL", self.arte)
        self.assertIn("SENAL_4", self.arte)
        self.assertIn("_montar_barandillas()", self.arte)
        self.assertIn("_puerta_cortafuegos", self.arte)
        self.assertIn("_extintor", self.arte)
        self.assertNotIn("CollisionShape3D", self.arte)
        self.assertNotIn("StaticBody3D", self.arte)


if __name__ == "__main__":
    unittest.main()
