from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CREDITOS = ROOT / "godot" / "guion" / "creditos_inicio_cinematica.gd"
INICIO = ROOT / "godot" / "guion" / "inicio_app.gd"
REPRODUCTOR = ROOT / "godot" / "guion" / "cinematica_app.gd"


class CreditosInicioCinematicaTest(unittest.TestCase):
    def setUp(self) -> None:
        self.creditos = CREDITOS.read_text(encoding="utf-8")
        self.inicio = INICIO.read_text(encoding="utf-8")
        self.reproductor = REPRODUCTOR.read_text(encoding="utf-8")

    def test_consume_fuente_canonica_sin_duplicar_creditos(self) -> None:
        self.assertIn("CreditosInicio.bloques_completos()", self.creditos)
        self.assertNotIn("eGurucharri", self.creditos)
        self.assertNotIn("VaroTv7", self.creditos)
        self.assertNotIn("Godot Engine", self.creditos)

    def test_todos_los_planos_son_3d_y_reutilizan_espacios_reales(self) -> None:
        self.assertIn('"tipo": "3d"', self.creditos)
        self.assertNotIn('"tipo": "2d"', self.creditos)
        self.assertNotIn("MeshInstance3D", self.creditos)
        self.assertNotIn("BoxMesh", self.creditos)
        for espacio in ("EspaciosCatalogo.OFICINA", "EspaciosCatalogo.CALLE", "EspaciosCatalogo.CASA"):
            self.assertIn(espacio, self.creditos)
        self.assertIn('"decorado": _decorado_para(indice)', self.creditos)

    def test_direccion_y_titulo_consumen_los_datos_del_bloque(self) -> None:
        self.assertIn('bloque_id == "direccion"', self.creditos)
        self.assertIn('bloque_id == "titulo"', self.creditos)
        self.assertIn('primera.get("nombre", bloque.get("titulo", ""))', self.creditos)
        self.assertIn('"fundido_hasta"] = 0.18', self.creditos)

    def test_listas_largas_se_paginan_sin_inventar_contenido(self) -> None:
        self.assertIn("const ENTRADAS_POR_PLANO := 4", self.creditos)
        self.assertIn('entrada.get("nombre", "")', self.creditos)
        self.assertIn('entrada.get("licencia", "")', self.creditos)
        self.assertIn('paginas.append("  ·  ".join(PackedStringArray(actual)))', self.creditos)

    def test_inicio_reproduce_una_sola_vez_por_sesion(self) -> None:
        self.assertIn("static var _apertura_creditos_mostrada := false", self.inicio)
        self.assertIn("func _iniciar_apertura_creditos() -> void:", self.inicio)
        self.assertIn("_apertura_creditos_mostrada = true", self.inicio)
        self.assertIn("CreditosInicioCinematica.planos()", self.inicio)
        self.assertIn(
            "app.reproducir(rodaje, CreditosInicioCinematica.ID)",
            self.inicio,
        )
        self.assertNotIn("cinematicas_vistas", self.inicio)

    def test_apertura_bloquea_menu_y_restaura_foco(self) -> None:
        self.assertIn("_envoltorio.visible = false", self.inicio)
        self.assertIn("_envoltorio.visible = true", self.inicio)
        self.assertIn("_diorama.configurar_activo(false)", self.inicio)
        self.assertIn("_diorama.configurar_activo(true)", self.inicio)
        self.assertIn("_enfocar_menu_inicial()", self.inicio)

    def test_skip_reutiliza_teclado_mando_y_añade_raton(self) -> None:
        self.assertIn('evento.is_action_pressed("ui_accept")', self.reproductor)
        self.assertIn('evento.is_action_pressed("ui_cancel")', self.reproductor)
        self.assertIn("evento is InputEventMouseButton", self.inicio)
        self.assertIn("click.button_index == MOUSE_BUTTON_LEFT", self.inicio)
        self.assertIn('_apertura_creditos.call("saltar")', self.inicio)

    def test_reduccion_de_movimiento_sigue_en_el_reproductor_comun(self) -> None:
        self.assertIn(
            'PreferenciasSiga.cargar().get("reduccion_movimiento", false)',
            self.reproductor,
        )
        self.assertNotIn("PreferenciasSiga", self.creditos)
        self.assertIn('"camara_desde":', self.creditos)
        self.assertIn('"mira_desde":', self.creditos)


if __name__ == "__main__":
    unittest.main()
