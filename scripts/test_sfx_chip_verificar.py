import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
GENERADOR = ROOT / "tools" / "sfx_chip" / "generar.py"

spec = importlib.util.spec_from_file_location("sfx_chip_generar", GENERADOR)
generador = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(generador)


class SfxChipVerificarTest(unittest.TestCase):
    def test_verificar_exito_con_recetas_canonicas(self):
        """Verifica que verificar() finaliza sin error (retorna None) para todas las recetas."""
        resultado = generador.verificar()
        self.assertIsNone(resultado)

    def test_verificar_falla_si_se_altera_hash_esperado(self):
        """Verifica que verificar() lanza SystemExit si un hash esperado es alterado."""
        primer_nombre = next(iter(generador.RECETAS))
        receta_original = generador.RECETAS[primer_nombre]
        hash_original = receta_original["wav_sha256"]

        hash_corrupto = "0" * len(hash_original) if hash_original != "0" * len(hash_original) else "1" * len(hash_original)
        receta_modificada = dict(receta_original)
        receta_modificada["wav_sha256"] = hash_corrupto

        with patch.dict(generador.RECETAS, {primer_nombre: receta_modificada}):
            with self.assertRaises(SystemExit) as cm:
                generador.verificar()
            self.assertIn(primer_nombre, str(cm.exception))

    def test_verificar_falla_si_se_altera_parametro_receta(self):
        """Verifica que verificar() lanza SystemExit si se altera un parámetro que cambia los bytes sintetizados."""
        primer_nombre = next(iter(generador.RECETAS))
        receta_original = generador.RECETAS[primer_nombre]

        receta_modificada = dict(receta_original)
        receta_modificada["gain"] = float(receta_original["gain"]) + 0.05

        with patch.dict(generador.RECETAS, {primer_nombre: receta_modificada}):
            with self.assertRaises(SystemExit) as cm:
                generador.verificar()
            self.assertIn(primer_nombre, str(cm.exception))

    def test_verificar_cubre_todas_las_recetas(self):
        """Verifica que verificar() evalúa cada entrada en RECETAS y que todas tienen hash de 64 caracteres."""
        self.assertGreater(len(generador.RECETAS), 0)
        for nombre, receta in generador.RECETAS.items():
            self.assertIn("wav_sha256", receta, nombre)
            self.assertEqual(len(receta["wav_sha256"]), 64, nombre)


if __name__ == "__main__":
    unittest.main()
