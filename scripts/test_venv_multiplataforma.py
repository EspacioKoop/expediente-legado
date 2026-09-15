"""Los instaladores del repo crean venvs y CI los ejecuta en Linux y en Windows.

Un venv coloca sus ejecutables en `bin/` en POSIX y en `Scripts/` en Windows.
Asumir `bin/` rompió el job `native-gb-windows`; estas pruebas fijan que ninguno
de los dos scripts vuelva a codificar la ruta a mano.
"""

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
GUIONES = (
    ROOT / "scripts" / "preparar_emulador_gb.sh",
    ROOT / "scripts" / "check_gdscript.sh",
)


class VenvMultiplataformaTest(unittest.TestCase):
    def test_cada_guion_detecta_el_directorio_del_venv(self):
        for guion in GUIONES:
            with self.subTest(guion=guion.name):
                texto = guion.read_text(encoding="utf-8")
                self.assertIn("venv_bin", texto, "debe detectar el directorio, no asumirlo")
                self.assertIn("/Scripts", texto, "debe contemplar la ruta de Windows")

    def test_nadie_invoca_un_ejecutable_por_una_ruta_bin_fija(self):
        # La rama `bin` dentro de venv_bin() es legítima: es el fallback POSIX.
        # Lo que no puede volver a aparecer es *invocar* algo por esa ruta
        # —"$venv/bin/python", "$VENV/bin/gdformat"—, que es lo que falló en
        # windows-latest con exit 127.
        patron = re.compile(r'"\$\{?(?:venv|VENV)\}?/bin/\w')
        for guion in GUIONES:
            with self.subTest(guion=guion.name):
                fuera = [
                    linea.strip()
                    for linea in guion.read_text(encoding="utf-8").splitlines()
                    if patron.search(linea)
                ]
                self.assertEqual([], fuera, f"ejecutable invocado por ruta fija: {fuera}")


if __name__ == "__main__":
    unittest.main()
