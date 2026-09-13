import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")
DIA_GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"


class PistaOniricaTest(unittest.TestCase):
    def test_contrato_ejecutable_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_pista_onirica.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 23, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)

    def test_el_dia_conecta_resultado_registro_y_guardado(self):
        codigo = DIA_GATO.read_text(encoding="utf-8")
        self.assertIn("func conectar_recompensa_onirica(nucleo, caso: Dictionary) -> bool:", codigo)
        self.assertIn('nucleo.has_signal("resultado")', codigo)
        self.assertIn("nucleo.resultado.connect(callback)", codigo)
        self.assertIn("PistaOnirica.resolver(caso, resultado)", codigo)
        self.assertIn("PistaOnirica.registrar(partida.estado, pista)", codigo)
        self.assertIn('_guardar_o_avisar("")', codigo)

    def test_el_cableado_no_escribe_partida_por_su_cuenta(self):
        codigo = DIA_GATO.read_text(encoding="utf-8")
        bloque = codigo.split("func conectar_recompensa_onirica", 1)[1]
        self.assertNotIn("partida.guardar(", bloque)
        self.assertNotIn("pistas_descubiertas.append", bloque)


if __name__ == "__main__":
    unittest.main()
