from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "assets" / "quaternius-ultimate-buildings.md"
GITATTRIBUTES = ROOT / ".gitattributes"


class TestQuaterniusUltimateBuildingsContract(unittest.TestCase):
    def test_fuente_licencia_y_pack_quedan_fijados(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("https://quaternius.com/packs/ultimatetexturedbuildings.html", texto)
        self.assertIn("Quaternius", texto)
        self.assertIn("CC0", texto)
        self.assertIn("76 modelos", texto)
        for formato in ("FBX", "OBJ", "Blend"):
            self.assertIn(formato, texto)

    def test_primer_corte_se_limita_a_cuatro_roles(self):
        texto = DOC.read_text(encoding="utf-8")
        for rol in (
            "bloque residencial bajo/medio",
            "bloque residencial alto",
            "edificio terciario/oficinas",
            "pieza comercial o de esquina",
        ):
            self.assertIn(rol, texto)
        self.assertIn("exactamente una pieza real", texto)
        self.assertIn("No se sustituye por otro pack", texto)

    def test_no_se_inventan_nombres_o_rutas_del_pack(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("no inventa rutas ni nombres de modelos", texto)
        self.assertIn("rol -> nombre/ruta real del fichero", texto)
        self.assertIn("inventariar los nombres/rutas reales", texto)

    def test_uso_es_fondo_no_interactivo(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("fondo visual", texto)
        self.assertIn("sin interiores navegables", texto)
        self.assertIn("sin navegación, IA ni colisiones de personaje", texto)
        self.assertIn("sin interacción ni colisiones de gameplay", texto)

    def test_contrato_exige_lod_y_medicion_de_coste(self):
        texto = DOC.read_text(encoding="utf-8")
        for banda in ("mid/far", "far", "very far"):
            self.assertIn(banda, texto)
        self.assertIn("conteo de instancias", texto)
        self.assertIn("triángulos/vértices", texto)
        self.assertIn("número de materiales/texturas", texto)
        self.assertIn("captura desde una cámara jugable", texto)

    def test_adaptacion_visual_siga_98_queda_acotada(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("Paleta y materiales SIGA-98", texto)
        self.assertIn("saturación contenida", texto)
        self.assertIn("contraste menor", texto)
        self.assertIn("niebla/distancia", texto)
        self.assertIn("repetición de atlas/materiales", texto)

    def test_obj_es_preferido_sin_prohibir_fbx_justificado(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("se prioriza **OBJ**", texto)
        self.assertIn("FBX puede usarse", texto)
        self.assertIn("no se convierten todos los modelos", texto)

    def test_binarios_relevantes_estan_cubiertos_por_lfs(self):
        atributos = GITATTRIBUTES.read_text(encoding="utf-8")
        self.assertIn("*.fbx   filter=lfs", atributos)
        self.assertIn("*.blend filter=lfs", atributos)
        self.assertIn("*.png   filter=lfs", atributos)
        self.assertIn("*.jpg   filter=lfs", atributos)
        self.assertIn("*.obj    text", atributos)

    def test_pr_binario_exige_procedencia_hash_y_lfs_real(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("godot/assets/procedencia.json", texto)
        self.assertIn("sha256", texto)
        self.assertIn("Git LFS real", texto)
        self.assertIn("el fichero exacto que entra", texto)

    def test_documento_no_finge_cierre_del_issue(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("Este documento no cierra #218 por sí solo", texto)
        self.assertIn("Criterio de cierre", texto)
        self.assertIn("coste básico medido", texto)
        self.assertIn("validación visual", texto)


if __name__ == "__main__":
    unittest.main()
