from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
MENU = (ROOT / "godot/guion/menu_global.gd").read_text(encoding="utf-8")
PRESENTACION = json.loads(
    (ROOT / "godot/datos/sellos_presentacion.json").read_text(encoding="utf-8")
)


class SellosMenuTests(unittest.TestCase):
    def test_menu_expone_hoja_de_sellos(self):
        self.assertEqual(PRESENTACION["titulo"], "Sellos SIGA")
        self.assertIn("RUTA_PRESENTACION_SELLOS", MENU)
        self.assertIn("_cargar_presentacion_sellos", MENU)
        self.assertIn("_mostrar_sellos", MENU)
        self.assertIn("_panel_sellos", MENU)

    def test_hoja_reutiliza_catalogo_y_estado_existentes(self):
        self.assertIn("Sellos.catalogo()", MENU)
        self.assertIn("Sellos.tiene_sello(_estado_partida_actual(), sello_id)", MENU)
        self.assertIn('var marca := "◆" if obtenido else "◇"', MENU)

    def test_no_concede_recompensas_desde_la_presentacion(self):
        bloque = MENU.split("func _sellos_contenido", 1)[1].split("func _montar_remapeo", 1)[0]
        for prohibido in [
            "registrar_sello(",
            "dinero",
            "acciones",
            "pistas_descubiertas",
            "guardar(",
        ]:
            self.assertNotIn(prohibido, bloque)

    def test_sellos_no_reemplazan_opciones_ni_continuar(self):
        self.assertIn("_continuar", MENU)
        self.assertIn("_opciones", MENU)
        self.assertIn("_sellos_volver", MENU)


if __name__ == "__main__":
    unittest.main()
