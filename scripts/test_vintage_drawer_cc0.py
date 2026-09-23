from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "arte" / "vintage_wooden_drawer.gd"
DRESSING = ROOT / "godot" / "guion" / "dia_dressing_cc0_app.gd"


class VintageDrawerCC0Test(unittest.TestCase):
    def test_documenta_fuente_autor_y_licencia_cc0(self) -> None:
        codigo = MODELO.read_text(encoding="utf-8")
        self.assertIn("https://polyhaven.com/a/vintage_wooden_drawer_01", codigo)
        self.assertIn("James Ray Cock", codigo)
        self.assertIn("CC0-1.0", codigo)
        self.assertIn("0,9 m", codigo)
        self.assertIn("~5K triángulos", codigo)

    def test_reconstruye_silueta_sin_binarios_ni_descarga_runtime(self) -> None:
        codigo = MODELO.read_text(encoding="utf-8")
        self.assertIn("const CAJONES := 6", codigo)
        self.assertIn("const TAMANO := Vector3(0.90, 1.12, 0.46)", codigo)
        self.assertIn("MultiMeshInstance3D", codigo)
        self.assertEqual(codigo.count('raiz.add_child(_multimesh('), 3)
        self.assertIn("Espacio3D.shader_del_sitio()", codigo)
        for token in ("HTTPRequest", "HTTPClient", "FileAccess.open", "load(\"http"):
            self.assertNotIn(token, codigo)

    def test_el_archivo_monta_una_instancia_solida_y_examinable(self) -> None:
        codigo = DRESSING.read_text(encoding="utf-8")
        self.assertIn("_archivador_vintage_cc0(mundo)", codigo)
        self.assertIn('cuerpo.name = "ArchivadorVintageCC0"', codigo)
        self.assertIn("VintageWoodenDrawer.TAMANO", codigo)
        self.assertIn("VintageWoodenDrawer.crear()", codigo)
        self.assertIn("StaticBody3D.new()", codigo)
        self.assertIn("BoxShape3D.new()", codigo)
        self.assertIn('"archivador vintage"', codigo)
        self.assertIn("cuerpo.rotation_degrees.y = 90.0", codigo)

    def test_se_coloca_al_final_de_la_bateria_de_archivadores(self) -> None:
        codigo = DRESSING.read_text(encoding="utf-8")
        self.assertIn("Vector3(5.50, tam.y * 0.5, 4.42)", codigo)
        self.assertIn("El frente mira hacia el pasillo central", codigo)


if __name__ == "__main__":
    unittest.main()
