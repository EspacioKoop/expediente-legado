import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "assets" / "school-classrooms-styloo.md"
MANIFEST = ROOT / "docs" / "assets" / "school-classrooms-styloo.manifest.json"
IMPORTER = ROOT / "scripts" / "preparar_school_classrooms_styloo.py"
GITATTRIBUTES = ROOT / ".gitattributes"


class TestSchoolClassroomsStylooContract(unittest.TestCase):
    def test_fuente_licencia_y_autor_quedan_fijados(self):
        texto = DOC.read_text(encoding="utf-8")
        datos = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertIn("https://styloo.itch.io/classroom-asset-pack", texto)
        self.assertEqual(datos["fuente"], "https://styloo.itch.io/classroom-asset-pack")
        self.assertEqual(datos["autor"], "styloo")
        self.assertEqual(datos["licencia"], "CC0-1.0")
        self.assertIn("Creative Commons Zero v1.0 Universal", texto)

    def test_zip_real_ya_tiene_revision_y_rutas_exactas(self):
        datos = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertRegex(datos["archivo_sha256"], r"^[0-9a-f]{64}$")
        self.assertEqual(datos["archivo_entradas"], 409)
        por_id = {asset["id"]: asset for asset in datos["assets"]}
        self.assertEqual(
            por_id["desk"]["miembro_zip"],
            "StylooClassroomAssetPack GLTF & FBX/principal office/GLTF/PRINCIPALOFFICEdesk.glb",
        )
        self.assertEqual(
            por_id["old_pc"]["miembro_zip"],
            "StylooClassroomAssetPack GLTF & FBX/computer/GLTF/COMPUTERpcold.glb",
        )
        self.assertEqual(
            por_id["blackboardbig"]["miembro_zip"],
            "StylooClassroomAssetPack GLTF & FBX/classroom/GLTF/blackboardbig.glb",
        )
        for asset in datos["assets"]:
            self.assertRegex(asset["sha256"], r"^[0-9a-f]{64}$")
            self.assertGreater(asset["bytes"], 0)
            self.assertNotIn("demoscene", asset["miembro_zip"].lower())

    def test_primer_corte_es_pequeno_y_administrativo(self):
        datos = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(
            datos["lotes"]["administrativo"],
            ["desk", "principal_chair", "shelf", "telephone", "old_pc", "printer"],
        )
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("No importar el pack completo", texto)
        self.assertIn("seis piezas", texto)

    def test_contexto_pc_y_extension_escolar_quedan_separados(self):
        datos = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(
            datos["lotes"]["contexto_informatico_1998"],
            ["old_monitor", "keyboard", "mouse"],
        )
        self.assertEqual(datos["lotes"]["escuela_sueno"], ["locker", "blackboardbig"])
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("#284", texto)
        self.assertIn("componer la escena escolar propia", texto)

    def test_importador_no_escribe_runtime_ni_fabrica_lfs(self):
        texto = IMPORTER.read_text(encoding="utf-8")
        self.assertIn("no escribe en ``godot/assets``", texto)
        self.assertIn("no crea punteros LFS", texto)
        self.assertIn("dist", texto)
        self.assertNotIn("subprocess", texto)

    def test_binarios_relevantes_estan_cubiertos_por_lfs(self):
        atributos = GITATTRIBUTES.read_text(encoding="utf-8")
        self.assertIn("*.glb   filter=lfs", atributos)
        self.assertIn("*.fbx   filter=lfs", atributos)
        self.assertIn("*.png   filter=lfs", atributos)

    def test_documenta_escala_complejidad_y_fuente_de_licencia(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("5.302", texto)
        self.assertIn("22.588", texto)
        self.assertIn("README interno no declara la licencia", texto)
        self.assertIn("Git LFS real", texto)
        self.assertIn("godot/assets/procedencia.json", texto)


if __name__ == "__main__":
    unittest.main()
