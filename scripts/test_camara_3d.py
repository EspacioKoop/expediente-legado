from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
CAMINANTE = ROOT / "godot" / "guion" / "caminante.gd"
PREFERENCIAS = ROOT / "godot" / "guion" / "preferencias_siga.gd"
MENU = ROOT / "godot" / "guion" / "menu_global.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


class Camara3DTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.caminante = CAMINANTE.read_text(encoding="utf-8")
        cls.preferencias = PREFERENCIAS.read_text(encoding="utf-8")
        cls.menu = MENU.read_text(encoding="utf-8")
        cls.textos = TEXTOS.read_text(encoding="utf-8")

    def test_camara_consumidora_de_preferencias_persistentes(self) -> None:
        self.assertIn("PreferenciasSiga.cargar()", self.caminante)
        for clave in (
            "sensibilidad_camara_raton",
            "sensibilidad_camara_mando",
            "invertir_camara_y",
        ):
            self.assertIn(clave, self.caminante)
            self.assertIn(clave, self.preferencias)

    def test_opciones_exponen_camara_y_la_actualizan_en_vivo(self) -> None:
        for clave in (
            "sensibilidad_camara_raton",
            "sensibilidad_camara_mando",
            "invertir_camara_y",
        ):
            self.assertIn(clave, self.menu)
        self.assertIn("PreferenciasSiga.SENSIBILIDAD_CAMARA_MIN", self.menu)
        self.assertIn("PreferenciasSiga.SENSIBILIDAD_CAMARA_MAX", self.menu)
        self.assertIn(
            'call_group("caminante_camara", "recargar_preferencias_camara")',
            self.menu,
        )
        self.assertIn('const GRUPO_CAMARA := "caminante_camara"', self.caminante)
        self.assertIn("add_to_group(GRUPO_CAMARA)", self.caminante)
        self.assertIn("func recargar_preferencias_camara()", self.caminante)

    def test_opciones_de_camara_usan_catalogo_traducible(self) -> None:
        for clave in (
            "MENU_GLOBAL_SENSIBILIDAD_RATON",
            "MENU_GLOBAL_SENSIBILIDAD_MANDO",
            "MENU_GLOBAL_INVERTIR_CAMARA_Y",
        ):
            self.assertIn(clave, self.textos)
            self.assertIn(f'tr("{clave}")', self.menu)

    def test_raton_y_stick_comparten_pitch_acotado_y_deadzone(self) -> None:
        self.assertIn("InputEventMouseMotion", self.caminante)
        self.assertIn(
            '"mirar_izquierda", "mirar_derecha", "mirar_arriba", "mirar_abajo"',
            self.caminante,
        )
        self.assertIn("const TOPE_VERTICAL := deg_to_rad(85.0)", self.caminante)
        self.assertGreaterEqual(self.caminante.count("-TOPE_VERTICAL"), 2)
        self.assertGreaterEqual(self.caminante.count("TOPE_VERTICAL"), 3)
        self.assertIn("const ZONA_MUERTA := 0.12", self.caminante)
        self.assertIn(
            "(magnitud - ZONA_MUERTA) / (1.0 - ZONA_MUERTA)",
            self.caminante,
        )

    def test_raton_gira_antes_de_que_la_gui_pueda_consumir_mousemotion(self) -> None:
        entrada = self.caminante.split(
            "func _input(evento: InputEvent) -> void:", 1
        )[1].split("func _unhandled_input(evento: InputEvent) -> void:", 1)[0]
        no_gestionado = self.caminante.split(
            "func _unhandled_input(evento: InputEvent) -> void:", 1
        )[1].split("func _physics_process", 1)[0]

        self.assertIn("InputEventMouseMotion", entrada)
        self.assertIn("Input.MOUSE_MODE_CAPTURED", entrada)
        self.assertIn("is_physics_processing()", entrada)
        self.assertIn("rotate_y(", entrada)
        self.assertIn("_camara.rotation.x", entrada)
        self.assertNotIn("rotate_y(", no_gestionado)

    def test_movimiento_tiene_aceleracion_frenado_y_analogico_real(self) -> None:
        self.assertIn("const ACELERACION := 10.0", self.caminante)
        self.assertIn("const FRENADO := 14.0", self.caminante)
        self.assertIn(
            "move_toward(velocity.x, objetivo.x, respuesta * delta)",
            self.caminante,
        )
        self.assertIn(
            "move_toward(velocity.z, objetivo.z, respuesta * delta)",
            self.caminante,
        )
        self.assertIn("Vector3(entrada.x, 0, entrada.y)", self.caminante)
        fisica = self.caminante.split("func _physics_process", 1)[1].split(
            "func _mirar_con_mando", 1
        )[0]
        self.assertNotIn(".normalized()", fisica)

    def test_escape_no_tiene_dos_duenos_y_detector_sigue_la_camara(self) -> None:
        self.assertNotIn('evento.is_action_pressed("ui_cancel")', self.caminante)
        self.assertIn("Input.MOUSE_MODE_CAPTURED", self.caminante)
        self.assertIn("InputEventMouseButton", self.caminante)
        self.assertIn("get_tree().paused", self.caminante)
        self.assertIn("_camara.add_child(_detector_interaccion)", self.caminante)

    def test_contrato_runtime_mousemotion(self) -> None:
        comprobar_contrato(
            self,
            "pruebas/pruebas_camara_396.gd",
            "Camara #396 runtime: OK",
            timeout=60,
        )


if __name__ == "__main__":
    unittest.main()
