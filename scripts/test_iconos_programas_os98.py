from pathlib import Path
import unittest
import xml.etree.ElementTree as ET


RAIZ = Path(__file__).resolve().parents[1]
ARTE = RAIZ / "godot" / "arte" / "os98"
IDENTIDADES = (
    "explorador",
    "web98",
    "software",
    "correo",
    "bloc-notas",
    "calculadora",
    "catalogo-anomalias",
)


class IconosProgramasOS98Test(unittest.TestCase):
    def test_atlas_32_es_svg_valido_y_mide_siete_celdas(self) -> None:
        ruta = ARTE / "iconos_programas_32.svg"
        raiz = ET.fromstring(ruta.read_text(encoding="utf-8"))
        self.assertEqual(raiz.attrib.get("viewBox"), "0 0 224 32")
        self.assertNotEqual(raiz.attrib.get("shape-rendering"), "crispEdges")

    def test_atlas_16_es_svg_valido_y_mide_siete_celdas(self) -> None:
        ruta = ARTE / "iconos_programas_16.svg"
        raiz = ET.fromstring(ruta.read_text(encoding="utf-8"))
        self.assertEqual(raiz.attrib.get("viewBox"), "0 0 112 16")
        self.assertNotEqual(raiz.attrib.get("shape-rendering"), "crispEdges")

    def test_ambos_tamanos_tienen_las_mismas_identidades(self) -> None:
        for nombre in ("iconos_programas_32.svg", "iconos_programas_16.svg"):
            fuente = (ARTE / nombre).read_text(encoding="utf-8")
            for identidad in IDENTIDADES:
                self.assertIn(f'id="programa-{identidad}"', fuente, (nombre, identidad))

    def test_estilo_moderno_usa_curvas_y_gradientes(self) -> None:
        for nombre in ("iconos_programas_32.svg", "iconos_programas_16.svg"):
            fuente = (ARTE / nombre).read_text(encoding="utf-8")
            self.assertIn("linearGradient", fuente, nombre)
            self.assertIn("rx=", fuente, nombre)
            self.assertNotIn('shape-rendering="crispEdges"', fuente, nombre)

    def test_no_hay_texto_horneado_ni_marcas_comerciales(self) -> None:
        for nombre in ("iconos_programas_32.svg", "iconos_programas_16.svg"):
            fuente = (ARTE / nombre).read_text(encoding="utf-8").lower()
            self.assertNotIn("<text", fuente)
            self.assertNotIn("windows", fuente)
            self.assertNotIn("microsoft", fuente)
            self.assertNotIn("netscape", fuente)


if __name__ == "__main__":
    unittest.main()
