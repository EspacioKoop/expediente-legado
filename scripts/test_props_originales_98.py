from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "godot/arte/props_originales_98"
OBJS = [
    "telefono_fijo_base_98.obj",
    "telefono_auricular_98.obj",
    "lampara_pie_98.obj",
    "cuenco_gato_98.obj",
    "impresora_termica_98.obj",
    "consola_portatil_98.obj",
    "minicadena_98.obj",
]
CODE_REFS = {
    "godot/guion/telefono_fijo_interactivo_3d.gd": ["telefono_fijo_base_98.obj", "telefono_auricular_98.obj"],
    "godot/guion/casa_utileria.gd": ["lampara_pie_98.obj", "cuenco_gato_98.obj"],
    "godot/guion/impresora_termica_portatil_3d.gd": ["impresora_termica_98.obj"],
    "godot/guion/consola_portatil_98.gd": ["consola_portatil_98.obj"],
    "godot/guion/minicadena_domestica_98.gd": ["minicadena_98.obj"],
}
MARCAS = (
    "nintendo", "game boy", "sony", "sega", "panasonic", "philips", "canon",
    "epson", "hewlett", "coca-cola", "coke", "pocari", "kirin", "toshiba",
)

class PropsOriginales98Test(unittest.TestCase):
    def test_obj_textuales_y_con_geometria_real(self):
        self.assertTrue((ASSET_DIR / "props_originales_98.mtl").is_file())
        for nombre in OBJS:
            ruta = ASSET_DIR / nombre
            self.assertTrue(ruta.is_file(), nombre)
            texto = ruta.read_text(encoding="utf-8")
            self.assertIn("mtllib props_originales_98.mtl", texto)
            self.assertGreaterEqual(len(re.findall(r"^v ", texto, re.M)), 24, nombre)
            self.assertGreaterEqual(len(re.findall(r"^f ", texto, re.M)), 12, nombre)

    def test_sin_marcas_reales_en_fuentes(self):
        textos = [p.read_text(encoding="utf-8").lower() for p in ASSET_DIR.iterdir() if p.is_file()]
        unido = "\n".join(textos)
        for marca in MARCAS:
            self.assertNotIn(marca, unido)

    def test_runtime_referencia_todos_los_modelos(self):
        for relativo, modelos in CODE_REFS.items():
            texto = (ROOT / relativo).read_text(encoding="utf-8")
            for modelo in modelos:
                self.assertIn(f"props_originales_98/{modelo}", texto)

    def test_conserva_feedback_dinamico(self):
        telefono = (ROOT / "godot/guion/telefono_fijo_interactivo_3d.gd").read_text(encoding="utf-8")
        impresora = (ROOT / "godot/guion/impresora_termica_portatil_3d.gd").read_text(encoding="utf-8")
        portatil = (ROOT / "godot/guion/consola_portatil_98.gd").read_text(encoding="utf-8")
        self.assertIn('"PilotoTimbre"', telefono)
        self.assertIn('"PilotoMensajes"', telefono)
        self.assertIn('"LedImpresoraTermica"', impresora)
        self.assertIn('"TiraPapelTermico"', impresora)
        self.assertIn('"PantallaPortatil"', portatil)

if __name__ == "__main__":
    unittest.main()
