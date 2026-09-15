from pathlib import Path
import unittest
import xml.etree.ElementTree as ET


RAIZ = Path(__file__).resolve().parents[1]
ARTE = RAIZ / "godot" / "arte" / "os98"
VISUAL = RAIZ / "godot" / "guion" / "escritorio_siga_visual.gd"
ADAPTADOR = RAIZ / "godot" / "guion" / "dia_escritorio_siga_app.gd"


class EscritorioSigaVisualTest(unittest.TestCase):
    def test_assets_svg_son_validos_y_tienen_las_medidas_previstas(self):
        esperados = {
            "wallpaper.svg": "0 0 1024 768",
            "system_mark.svg": "0 0 18 18",
            "iconos_32.svg": "0 0 192 32",
            "iconos_16.svg": "0 0 96 16",
        }
        for nombre, view_box in esperados.items():
            ruta = ARTE / nombre
            self.assertTrue(ruta.is_file(), nombre)
            raiz = ET.fromstring(ruta.read_text(encoding="utf-8"))
            self.assertEqual(raiz.attrib.get("viewBox"), view_box, nombre)

    def test_atlas_conserva_las_seis_identidades_del_diseno(self):
        ids = ["siga", "equipo", "documentos", "red", "papelera", "ayuda"]
        for nombre in ("iconos_32.svg", "iconos_16.svg"):
            fuente = (ARTE / nombre).read_text(encoding="utf-8")
            for identidad in ids:
                self.assertIn(f'id="icon-{identidad}"', fuente, (nombre, identidad))

    def test_wallpaper_no_hornea_texto_ni_marcas_ajenas(self):
        fuente = (ARTE / "wallpaper.svg").read_text(encoding="utf-8").lower()
        self.assertNotIn("<text", fuente)
        self.assertNotIn("windows", fuente)
        self.assertNotIn("microsoft", fuente)

    def test_piel_visual_preload_y_recorta_los_atlas(self):
        fuente = VISUAL.read_text(encoding="utf-8")
        for ruta in (
            "res://arte/os98/wallpaper.svg",
            "res://arte/os98/system_mark.svg",
            "res://arte/os98/iconos_32.svg",
            "res://arte/os98/iconos_16.svg",
        ):
            self.assertIn(ruta, fuente)
        self.assertIn("extends EscritorioSiga", fuente)
        self.assertIn("AtlasTexture.new()", fuente)
        self.assertIn("STRETCH_KEEP_ASPECT_COVERED", fuente)
        self.assertIn("ORDEN_ICONOS", fuente)

    def test_el_adaptador_asigna_solo_iconos_a_apps_reales(self):
        fuente = ADAPTADOR.read_text(encoding="utf-8")
        self.assertIn("EscritorioSigaVisual.new()", fuente)
        self.assertIn('registrar_identidad_visual("siga-98", "siga")', fuente)
        self.assertIn('registrar_identidad_visual("ayuda-sistema", "ayuda")', fuente)
        for id_sin_app in ("equipo", "documentos", "red", "papelera"):
            self.assertNotIn(f'registrar_aplicacion("{id_sin_app}"', fuente)


if __name__ == "__main__":
    unittest.main()
