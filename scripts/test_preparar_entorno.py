from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "scripts" / "preparar_entorno.sh"


class PrepararEntornoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = GUION.read_text(encoding="utf-8")

    def test_es_ejecutable_y_tiene_sintaxis_valida(self):
        self.assertTrue(GUION.stat().st_mode & 0o111, "debe ser ejecutable")
        subprocess.run(["bash", "-n", str(GUION)], check=True, capture_output=True)

    def test_aborta_ante_el_primer_fallo(self):
        self.assertIn("set -euo pipefail", self.texto)

    def test_encadena_los_dos_pasos_de_build(self):
        self.assertIn("preparar_emulador_gb.sh linux-debug", self.texto)
        self.assertIn("preparar_emulador_gb.sh rom", self.texto)

    def test_no_recompila_lo_que_ya_existe(self):
        # La idempotencia es lo que hace barato ejecutarlo antes de cada sesión.
        self.assertIn('if [[ -x "$BIBLIOTECA" ]]', self.texto)
        self.assertIn('if compgen -G "godot/roms/*.gbc"', self.texto)

    def test_compara_la_linea_del_motor_sin_confundir_4_1_con_4_10(self):
        self.assertIn("cut -d. -f1,2", self.texto)

    def test_recuerda_el_gate_tal_y_como_lo_ejecuta_ci(self):
        self.assertIn("SIGA98_EXIGIR_EXTENSION=1 bash scripts/check_gdscript.sh", self.texto)
        self.assertIn("python3 scripts/verificar_godot.py", self.texto)


if __name__ == "__main__":
    unittest.main()
