from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
SELECTOR = ROOT / "godot" / "guion" / "selector_cartuchos_3d.gd"
PORTATIL = ROOT / "godot" / "guion" / "consola_portatil_98.gd"
TEXTOS = ROOT / "godot" / "datos" / "emulador_gb_textos.json"


class SelectorCartuchos3DTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.selector = SELECTOR.read_text(encoding="utf-8")
        cls.portatil = PORTATIL.read_text(encoding="utf-8")
        cls.textos = json.loads(TEXTOS.read_text(encoding="utf-8"))

    def test_portatil_conserva_backend_y_sustituye_solo_presentacion(self):
        self.assertIn("EmuladorPortatilAudioApp.new()", self.portatil)
        self.assertIn("SelectorCartuchos3D.instalar(_app)", self.portatil)
        self.assertLess(
            self.portatil.index("_app.abrir()"),
            self.portatil.index("SelectorCartuchos3D.instalar(_app)"),
        )

    def test_selector_es_un_subviewport_3d_real(self):
        for termino in (
            "SubViewportContainer.new()",
            "SubViewport.new()",
            "own_world_3d = true",
            "WorldEnvironment.new()",
            "Camera3D.new()",
            "DirectionalLight3D.new()",
            "BoxMesh.new()",
            "QuadMesh.new()",
            "Label3D.new()",
        ):
            self.assertIn(termino, self.selector)

    def test_reutiliza_catalogo_y_arte_local_de_cartuchos(self):
        self.assertIn("RomsPropias.en_consola(compradas)", self.selector)
        self.assertIn("CatalogoRomsUsuario.listar()", self.selector)
        self.assertIn(
            'RUTA_ETIQUETAS := "res://arte/consola98/cartuchos/"',
            self.selector,
        )
        self.assertIn("ResourceLoader.exists(ruta)", self.selector)
        self.assertNotIn("http://", self.selector)
        self.assertNotIn("https://", self.selector)

    def test_navegacion_cubre_raton_teclado_y_mando(self):
        for termino in (
            "anterior.pressed.connect(_mover.bind(-1))",
            "siguiente.pressed.connect(_mover.bind(1))",
            "_insertar.pressed.connect(_insertar_actual)",
            "KEY_LEFT",
            "KEY_RIGHT",
            "KEY_ENTER",
            "JOY_BUTTON_DPAD_LEFT",
            "JOY_BUTTON_DPAD_RIGHT",
            "JOY_BUTTON_A",
        ):
            self.assertIn(termino, self.selector)

    def test_insertar_anima_hacia_la_ranura_y_delega_la_carga(self):
        self.assertIn("DURACION_INSERCION := 0.14", self.selector)
        self.assertIn("func _animar_insercion()", self.selector)
        self.assertIn('"position"', self.selector)
        self.assertIn("Vector3(0.0, -0.43, 0.08)", self.selector)
        self.assertIn('_app.call("_cargar_rom", ruta)', self.selector)
        self.assertNotIn("load_rom", self.selector)
        self.assertNotIn("save_ram", self.selector)

    def test_textos_del_selector_estan_en_el_catalogo(self):
        self.assertEqual(self.textos["selector_anterior"], "Cartucho anterior")
        self.assertEqual(self.textos["selector_siguiente"], "Cartucho siguiente")
        self.assertIn("%s", self.textos["selector_insertar"])


if __name__ == "__main__":
    unittest.main()
