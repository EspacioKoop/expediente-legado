from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "assets" / "school-classrooms-styloo.md"
GITATTRIBUTES = ROOT / ".gitattributes"


class TestSchoolClassroomsStylooContract(unittest.TestCase):
    def test_fuente_licencia_y_autor_quedan_fijados(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("https://styloo.itch.io/classroom-asset-pack", texto)
        self.assertIn("Creative Commons Zero v1.0 Universal", texto)
        self.assertIn("CC0-1.0", texto)
        self.assertIn("styloo", texto)

    def test_primer_corte_es_pequeno_y_administrativo(self):
        texto = DOC.read_text(encoding="utf-8")
        for pieza in (
            "`desk`",
            "`principal's chair`",
            "`shelf`",
            "`telephone`",
            "`old pc`",
            "`printer`",
        ):
            self.assertIn(pieza, texto)
        self.assertIn("No importar el pack completo", texto)
        self.assertIn("No se inventarán rutas de archivo", texto)

    def test_demos_y_candidatos_temporalmente_ambiguos_quedan_fuera(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("no se reutilizará la *classroom demo scene*", texto.lower())
        self.assertIn("`new pc`", texto)
        self.assertIn("`new monitor`", texto)
        self.assertIn("`router`", texto)
        self.assertIn("`usb keys`", texto)
        self.assertIn("lectura visual", texto)

    def test_glb_individual_es_el_formato_preferido(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("preferir el **GLB individual**", texto)
        self.assertIn("usar FBX solo como alternativa", texto)
        self.assertIn("No se fijará un factor común", texto)

    def test_binarios_relevantes_estan_cubiertos_por_lfs(self):
        atributos = GITATTRIBUTES.read_text(encoding="utf-8")
        self.assertIn("*.glb   filter=lfs", atributos)
        self.assertIn("*.fbx   filter=lfs", atributos)
        self.assertIn("*.png   filter=lfs", atributos)

    def test_pr_binario_exige_procedencia_hash_y_lfs_real(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("godot/assets/procedencia.json", texto)
        self.assertIn("sha256", texto)
        self.assertIn("Git LFS real", texto)
        self.assertIn("el fichero exacto que entra", texto)

    def test_extension_escolar_queda_separada_para_284(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("`lockers`", texto)
        self.assertIn("`blackboardbig`", texto)
        self.assertIn("#284", texto)
        self.assertIn("componer la escena escolar propia", texto)


if __name__ == "__main__":
    unittest.main()
