from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
PRESETS = ROOT / "godot" / "export_presets.cfg"
PUBLICADOS = {"Linux x86_64", "Windows x86_64"}
RUTA_DEBUG = "debug/**"


def _presets(texto: str):
    """Devuelve solo los bloques de preset, sin sus secciones `.options`."""
    patron = re.compile(
        r'^\[preset\.(\d+)\]\n(?P<cuerpo>.*?)(?=^\[preset\.\d+(?:\.options)?\]|\Z)',
        re.MULTILINE | re.DOTALL,
    )
    for coincidencia in patron.finditer(texto):
        cuerpo = coincidencia.group("cuerpo")
        nombre = re.search(r'^name="([^"]+)"$', cuerpo, re.MULTILINE)
        if nombre:
            yield nombre.group(1), cuerpo


def _valor(cuerpo: str, clave: str) -> str:
    coincidencia = re.search(rf'^{re.escape(clave)}="([^"]*)"$', cuerpo, re.MULTILINE)
    return coincidencia.group(1) if coincidencia else ""


class DebugExportTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = PRESETS.read_text(encoding="utf-8")
        cls.presets = dict(_presets(cls.texto))

    def test_los_presets_publicados_estan_cubiertos(self):
        self.assertEqual(PUBLICADOS, PUBLICADOS.intersection(self.presets))

    def test_los_presets_publicados_excluyen_debug(self):
        for nombre in PUBLICADOS:
            with self.subTest(preset=nombre):
                exclusiones = {
                    ruta.strip()
                    for ruta in _valor(self.presets[nombre], "exclude_filter").split(",")
                    if ruta.strip()
                }
                self.assertIn(RUTA_DEBUG, exclusiones)

    def test_debug_no_se_reintroduce_por_include_filter(self):
        for nombre in PUBLICADOS:
            with self.subTest(preset=nombre):
                inclusiones = _valor(self.presets[nombre], "include_filter")
                self.assertNotIn("debug/", inclusiones)


if __name__ == "__main__":
    unittest.main()
