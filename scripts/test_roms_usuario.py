from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot" / "guion" / "catalogo_roms_usuario.gd"
PORTATIL = ROOT / "godot" / "guion" / "consola_portatil_98.gd"
DOC = ROOT / "docs" / "roms-usuario.md"


class RomsUsuarioTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalogo = CATALOGO.read_text(encoding="utf-8")
        cls.portatil = PORTATIL.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_carpeta_es_local_y_separada_del_repo(self):
        self.assertIn('const CARPETA := "user://roms"', self.catalogo)
        self.assertIn('DirAccess.open("user://")', self.catalogo)
        self.assertIn('make_dir_recursive("roms")', self.catalogo)
        self.assertIn("ProjectSettings.globalize_path(CARPETA)", self.catalogo)

    def test_solo_descubre_gb_gbc_sin_archivos_comprimidos(self):
        self.assertIn('const EXTENSIONES := ["gb", "gbc"]', self.catalogo)
        self.assertIn("nombre.get_extension().to_lower()", self.catalogo)
        self.assertNotIn('"zip"', self.catalogo)
        self.assertNotIn('"7z"', self.catalogo)

    def test_limita_tamano_y_no_carga_la_rom_entera(self):
        self.assertIn("const MIN_BYTES := 32 * 1024", self.catalogo)
        self.assertIn("const MAX_BYTES := 8 * 1024 * 1024", self.catalogo)
        self.assertIn("archivo.get_length()", self.catalogo)
        self.assertNotIn("get_file_as_bytes", self.catalogo)
        self.assertNotIn("get_buffer(", self.catalogo)

    def test_no_hay_descarga_ni_ejecucion_externa(self):
        for termino in (
            "HTTPRequest",
            "HTTPClient",
            "shell_open",
            "execute(",
            "download",
        ):
            self.assertNotIn(termino, self.catalogo)

    def test_portatil_usa_catalogo_sin_emular_aun(self):
        self.assertIn("CatalogoRomsUsuario.asegurar_carpeta()", self.portatil)
        self.assertIn("CatalogoRomsUsuario.listar()", self.portatil)
        self.assertNotIn("Peanut", self.portatil)
        self.assertNotIn("GDExtension", self.portatil)

    def test_documenta_responsabilidad_y_limites(self):
        self.assertIn("ROMs que tenga derecho a usar", self.doc)
        self.assertIn("no descarga ROMs", self.doc)
        self.assertIn("todavía no ejecuta", self.doc)
        self.assertIn("user://roms", self.doc)


if __name__ == "__main__":
    unittest.main()
