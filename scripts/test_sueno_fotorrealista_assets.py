import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "godot" / "arte" / "sueno_fotorrealista"
SHADER = ASSET_DIR / "material_microdetalle.gdshader"
SCENES = {
    "archivador_humedo.tscn": "archivador",
    "crt_condensacion.tscn": "televisor_casa",
    "fluorescente_oxidado.tscn": "fluorescente",
    "silla_reflejo.tscn": "silla",
}


class SuenoFotorrealistaAssetsTest(unittest.TestCase):
    def test_shader_es_pbr_procedural_y_sin_texturas_externas(self):
        shader = SHADER.read_text(encoding="utf-8")
        self.assertIn("shader_type spatial", shader)
        for termino in ("ALBEDO", "METALLIC", "ROUGHNESS", "SPECULAR", "EMISSION"):
            self.assertIn(termino, shader)
        self.assertNotIn("sampler2D", shader)
        self.assertIn("value_noise", shader)

    def test_cada_prop_declara_original_reconocible_y_shader_comun(self):
        for nombre, origen in SCENES.items():
            texto = (ASSET_DIR / nombre).read_text(encoding="utf-8")
            with self.subTest(nombre=nombre):
                self.assertIn(
                    'path="res://arte/sueno_fotorrealista/material_microdetalle.gdshader"',
                    texto,
                )
                self.assertIn(f'metadata/origen_reconocible = "{origen}"', texto)
                self.assertIn('metadata/uso = "sueno"', texto)
                self.assertIn('metadata/issue = 87', texto)
                self.assertIn('type="MeshInstance3D"', texto)

    def test_lote_no_introduce_binarios_marcas_ni_texto_narrativo(self):
        permitidos = {".tscn", ".gdshader", ".md"}
        for ruta in ASSET_DIR.iterdir():
            self.assertIn(ruta.suffix, permitidos)

        combinado = "\n".join(
            ruta.read_text(encoding="utf-8")
            for ruta in ASSET_DIR.iterdir()
            if ruta.is_file()
        ).lower()
        for marca in ("sony", "panasonic", "philips", "samsung", "lg electronics"):
            self.assertNotIn(marca, combinado)
        self.assertNotIn("res://assets/modelos/", combinado)

    def test_materiales_exponen_microdetalle_fisico(self):
        combinado = "\n".join(
            (ASSET_DIR / nombre).read_text(encoding="utf-8")
            for nombre in SCENES
        )
        for parametro in (
            "metallic_amount",
            "roughness_base",
            "grime_strength",
            "wetness",
            "micro_scale",
        ):
            self.assertIn(f"shader_parameter/{parametro}", combinado)
        self.assertIn("emission_energy", combinado)


if __name__ == "__main__":
    unittest.main()
