"""Efectos ligeros de ambiente: vapor, polvo, charcos y gotas con presupuesto cerrado."""

import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


RAIZ = Path(__file__).resolve().parents[1]
MODULO = (RAIZ / "godot/guion/efectos_ligeros.gd").read_text(encoding="utf-8")
DIA = (RAIZ / "godot/guion/dia_clima_app.gd").read_text(encoding="utf-8")
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class EfectosLigerosTest(unittest.TestCase):
    def test_se_monta_al_entrar_en_cada_fase(self):
        self.assertIn("EfectosLigeros.montar(", DIA)
        self.assertIn('get("reduccion_movimiento", false)', DIA)
        self.assertIn('bool(espacio.get("exterior", false))', DIA)

    def test_presupuesto_cerrado(self):
        for constante in ("PARTICULAS_VAPOR", "MAX_TAZAS", "PARTICULAS_POLVO", "MAX_LUCES_POLVO"):
            self.assertRegex(MODULO, rf"const {constante} := \d+")
        vapor = int(re.search(r"const PARTICULAS_VAPOR := (\d+)", MODULO).group(1))
        tazas = int(re.search(r"const MAX_TAZAS := (\d+)", MODULO).group(1))
        polvo = int(re.search(r"const PARTICULAS_POLVO := (\d+)", MODULO).group(1))
        luces = int(re.search(r"const MAX_LUCES_POLVO := (\d+)", MODULO).group(1))
        # Una décima parte de la lluvia exterior (1450 partículas) como mucho.
        self.assertLessEqual(vapor * tazas + polvo * luces, 160)

    def test_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(RAIZ / "godot"), "--script",
             "pruebas/pruebas_efectos_ligeros.gd"],
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120, check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIsNotNone(RESUMEN.search(resultado.stdout), resultado.stdout)
        self.assertNotIn("SHADER ERROR", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
