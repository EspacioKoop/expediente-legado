"""Contrato de montaje de créditos #795/#2527.

El corte 2 reemplaza la paginación de licencias en voz por un rodaje de
localizaciones únicas y rótulos destacados. El corte 4 conserva las
atribuciones completas por separado; no se deben duplicar en la apertura.
"""

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

    def test_fuente_canonica_sin_nombres_ni_licencias_duplicados(self) -> None:
        self.assertIn("CreditosInicio.bloques_completos()", self.creditos)
        for nombre in ("eGurucharri", "VaroTv7", "Godot Engine", "SameBoy"):
            self.assertNotIn(nombre, self.creditos)
        self.assertIn('entradas[entrada].get("nombre", "")', self.creditos)
        self.assertNotIn("ENTRADAS_POR_PLANO", self.creditos)
        self.assertNotIn("paginas.append", self.creditos)

    def test_rodaje_usa_lugares_3d_y_las_verticales(self) -> None:
        self.assertIn('"tipo": "3d"', self.creditos)
        self.assertNotIn('"tipo": "2d"', self.creditos)
        self.assertNotIn("MeshInstance3D", self.creditos)
        self.assertNotIn("BoxMesh", self.creditos)
        for espacio in ("OFICINA", "CALLE", "CASA"):
            self.assertIn("EspaciosCatalogo." + espacio, self.creditos)
        self.assertIn('"escena": ruta,', self.creditos)
        self.assertIn("const VERTICALES := [", self.creditos)
        self.assertEqual(self.creditos.count('"res://escenas/sueno_'), 11)
        self.assertIn("const CAMARAS_VERTICALES := {", self.creditos)
        self.assertIn('CAMARAS_VERTICALES.get(nombre, {})', self.creditos)
        self.assertIn('"carcasa": false', self.creditos)
        self.assertIn('"sombras": false', self.creditos)
        for identidad in (
            "SuenoVacio", "SuenoEscuela", "SuenoMontana",
            "SuenoDesierto", "SuenoCastillo", "SuenoDuat",
            "HorrorTexturas",
        ):
            self.assertIn(identidad + ".", self.creditos)

    def test_texto_selectivo_en_rotulo_y_no_en_voz(self) -> None:
        self.assertIn('"_rotulo_para(indice, bloques)"'.strip('"'), self.creditos)
        self.assertIn('"rotulo": _rotulo_para(indice, bloques)', self.creditos)
        self.assertNotIn('"voz":', self.creditos)
        self.assertIn('id = "direccion"', self.creditos)
        self.assertIn('id = "titulo"', self.creditos)
        self.assertIn('salida[salida.size() - 1]["fundido_hasta"] = 0.18', self.creditos)

    def test_localizaciones_y_travellings_distintos(self) -> None:
        self.assertIn("const ZONAS_DIA := [", self.creditos)
        self.assertEqual(self.creditos.count('"sitio": '), 22)
        self.assertIn('decorado["zona_creditos"] = String(zona["id"])', self.creditos)
        self.assertIn('decorado["bultos"] = objetos', self.creditos)
        self.assertIn('"camara_desde": camara + paso', self.creditos)
        self.assertIn('"mira_desde": mira', self.creditos)

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

    def test_skip_por_teclado_mando_y_raton(self) -> None:
        self.assertIn('evento.is_action_pressed("ui_accept")', self.reproductor)
        self.assertIn('evento.is_action_pressed("ui_cancel")', self.reproductor)
        self.assertIn("evento is InputEventMouseButton", self.inicio)
        self.assertIn("click.button_index == MOUSE_BUTTON_LEFT", self.inicio)
        self.assertIn('_apertura_creditos.call("saltar")', self.inicio)

    def test_reduccion_de_movimiento_heredada_del_reproductor(self) -> None:
        self.assertIn(
            'PreferenciasSiga.cargar().get("reduccion_movimiento", false)',
            self.reproductor,
        )
        self.assertNotIn("PreferenciasSiga", self.creditos)
        self.assertIn('if _reduccion_movimiento:', self.reproductor)
        self.assertIn("_camara.global_position = destino", self.reproductor)
        self.assertIn('"camara_desde":', self.creditos)


if __name__ == "__main__":
    unittest.main()
