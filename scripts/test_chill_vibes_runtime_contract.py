import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "godot/arte/chill_vibes_cc0.gd"
INDUSTRIAL = ROOT / "godot/arte/industrial_cc0.gd"
MATERIALIZER = ROOT / "scripts/materializar_chill_vibes_cc0.py"
MANIFEST = ROOT / "docs/assets/chill-vibes-art-jam-4.manifest.json"
ASSET_DIR = ROOT / "godot/assets/modelos/chill_vibes"


class ChillVibesRuntimeContractTest(unittest.TestCase):
    def test_primer_vertical_runtime_es_solo_pallet_y_crate(self):
        texto = RUNTIME.read_text(encoding="utf-8")
        self.assertIn('const PALLET := "chill_vibes/shipping_pallet"', texto)
        self.assertIn('const CRATE := "chill_vibes/crate"', texto)
        self.assertNotIn('"radio"', texto)
        self.assertNotIn('"flashlight"', texto)
        self.assertNotIn('"crowbar"', texto)

    def test_medidas_runtime_coinciden_con_manifiesto_auditado(self):
        datos = json.loads(MANIFEST.read_text(encoding="utf-8"))
        por_id = {asset["id"]: asset for asset in datos["assets"]}
        self.assertEqual(por_id["pallet"]["extents_crudos"], [0.8, 0.144, 1.2])
        self.assertEqual(por_id["crate"]["extents_crudos"], [1.0, 1.0, 1.0])
        texto = RUNTIME.read_text(encoding="utf-8")
        self.assertIn("Vector3(0.80, 0.144, 1.20)", texto)
        self.assertIn("Vector3(1.00, 1.00, 1.00)", texto)

    def test_runtime_exige_ambos_assets_y_no_descarga(self):
        texto = RUNTIME.read_text(encoding="utf-8")
        self.assertIn("Modelos.hay(PALLET) and Modelos.hay(CRATE)", texto)
        self.assertIn("Modelos.mueble", texto)
        self.assertNotIn("HTTPRequest", texto)
        self.assertNotIn("http://", texto)
        self.assertNotIn("https://", texto)

    def test_zona_industrial_conserva_fallback_procedural(self):
        texto = INDUSTRIAL.read_text(encoding="utf-8")
        self.assertIn("if not ChillVibesCC0.montar_lote_servicio(raiz):", texto)
        self.assertIn("_carro_plataforma(raiz)", texto)
        self.assertIn("_bobina(raiz)", texto)
        self.assertIn("_cuadro_electrico(raiz)", texto)
        self.assertIn("_foco_obra(raiz)", texto)

    def test_materializador_permite_corte_binario_exacto(self):
        texto = MATERIALIZER.read_text(encoding="utf-8")
        self.assertIn('"--asset"', texto)
        self.assertIn("seleccionar_assets_individuales", texto)
        self.assertIn("--asset y --lote son alternativas", texto)

    def test_este_pr_no_fabrica_binarios(self):
        self.assertFalse((ASSET_DIR / "shipping_pallet.glb").exists())
        self.assertFalse((ASSET_DIR / "crate.glb").exists())


if __name__ == "__main__":
    unittest.main()
