"""Contrato del gate visual reproducible de Simurgh #658."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaSimurgh658Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.simurgh = (ROOT / "godot/guion/sueno_simurgh.gd").read_text(encoding="utf-8")
        cls.captura = (ROOT / "godot/pruebas/capturar_simurgh_658.gd").read_text(
            encoding="utf-8"
        )
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-simurgh-658.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/simurgh-658/README.md"
        ).read_text(encoding="utf-8")

    def test_runtime_marca_las_tres_equivalencias(self):
        for ancla in ("ANCLA_PLUMA", "ANCLA_ARCHIVOS", "ANCLA_LAMPARA"):
            self.assertIn('set_meta("ancla_equivalencia", ' + ancla, self.simurgh)
        for nombre in (
            '"Pluma"',
            '"PasarelaPluma"',
            '"Archivadores"',
            '"CordilleraArchivos"',
            '"Lampara"',
            '"NidoLuminaria"',
        ):
            self.assertIn(nombre, self.simurgh)

    def test_captura_ambas_capas_para_cada_ancla(self):
        for prefijo in ("pluma", "archivos", "lampara"):
            self.assertIn(f'"id": "{prefijo}_escritorio"', self.captura)
            self.assertIn(f'"id": "{prefijo}_monumental"', self.captura)
            self.assertIn(f"{prefijo}_escritorio.png", self.workflow)
            self.assertIn(f"{prefijo}_monumental.png", self.workflow)

    def test_gate_fija_framing_sin_autoaprobar(self):
        self.assertIn("camara.is_position_in_frustum", self.captura)
        self.assertIn("camara.unproject_position", self.captura)
        self.assertIn('"veredicto_automatico": false', self.captura)
        self.assertIn('"requiere_revision_humana": true', self.captura)
        self.assertIn("actions/upload-artifact@v4", self.workflow)

    def test_documentacion_exige_comprension_humana(self):
        texto = self.docs.lower()
        self.assertIn("pluma", texto)
        self.assertIn("archivadores", texto)
        self.assertIn("lámpara", texto)
        self.assertIn("sin hud", texto)
        self.assertIn("revisión humana", texto)
        self.assertIn("no autoaprueba", texto)


if __name__ == "__main__":
    unittest.main()
